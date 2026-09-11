# UV包管理器使用经验 <!-- omit in toc -->

- [打包](#打包)
  - [Docker](#docker)
    - [优化层大小](#优化层大小)
- [坑](#坑)
    - [uv.lock记录安装镜像源](#uvlock记录安装镜像源)

## 打包
### Docker
[官方文档](https://docs.astral.sh/uv/guides/integration/docker)

#### 优化层大小
根据[官方文档](https://docs.astral.sh/uv/guides/integration/docker/#non-editable-installs)指引，可以将项目安装到一个虚拟环境中，再将虚拟环境整个复制到镜像中。  
但这样子会打出很大的层，特别是你同时配置了 `--compile-bytecode` 的情况下，单层100M+是家常便饭。

当然并不是说不能这么用，只是由于docker下载镜像可以同时下载多个层，并且重试和更新也是按层来的，因此一个太大的层会影响下载速度和更新体验
> ~并且官方文档中并没有考虑更新的情况，最终的镜像就只是一个**大** /app/.venv 层，每次更新都得重新下载~

<details>
<summary>Dockerfile</summary>

```dockerfile
# 1. 定义 uv 包镜像，指定版本
ARG UV_VERSION=0.12.6
FROM ghcr.io/astral-sh/uv:${UV_VERSION} AS uv

# 2. 定义Python基础环境，并拷贝 uv 二进制文件
FROM python:3.13-slim AS base_env
COPY --from=uv /uv /uvx /bin/
SHELL [ "/bin/bash", "-euo", "pipefail", "-c" ]
ENV UV_PYTHON_DOWNLOADS=0 PYTHONUNBUFFERED=1 UV_LINK_MODE=copy UV_NO_DEV=1
WORKDIR /app

FROM base_env AS builder
# 3. 安装项目依赖
COPY pyproject.toml README.md /app/

## 允许用户自定义镜像源
ARG UV_DEFAULT_INDEX
ARG UV_SYSTEM_CERTS

RUN --mount=type=cache,target=/root/.cache/uv\
    set -x\
 && export UV_DEFAULT_INDEX UV_SYSTEM_CERTS\
 && uv sync --no-install-project

# 4. 如果需要测试环境
FROM builder AS tester
ENV UV_NO_DEV=0

RUN --mount=type=cache,target=/root/.cache/uv\
    set -x\
 && uv sync --frozen --no-install-project --compile-bytecode

# 5. 将项目打包为 whl 文件
FROM builder AS packager

COPY src/ /app/src/

RUN --mount=type=cache,target=/root/.cache/uv \
    set -x\
 && uv build\
 && mv /app/dist /dist

# 6. 最终镜像
FROM python:3.13-slim AS release

WORKDIR /app
## (可选) 暴露CI信息到镜像
ARG CI_COMMIT_TAG
ARG CI_COMMIT_SHA
ARG CI_COMMIT_SHORT_SHA
ENV RELEASE_VRESION=${CI_COMMIT_TAG} COMMIT_SHA=${CI_COMMIT_SHA} COMMIT_SHORT_SHA=${CI_COMMIT_SHORT_SHA} UV_NO_DEV=1

## 复制项目运行环境
COPY --from=builder /app/ /app/

## (可选) 预编译字节码
### 视依赖情况，会增加 50%+ 的大小
RUN --mount=type=cache,target=/root/.cache/uv\
    --mount=from=uv,source=/uv,target=/bin/uv\
    set -x\
 && uv sync --frozen --no-install-project --compile-bytecode

## 安装项目 whl 文件
RUN --mount=type=cache,target=/root/.cache/uv\
    --mount=from=uv,source=/uv,target=/bin/uv\
    --mount=from=packager,source=/dist,target=/dist\
    set -x\
 && uv pip install /dist/*.whl --compile-bytecode
```

</details>

这样子打出来镜像就会有
| 层 | 大小 |
| --- | --- |
| 依赖 | 50% ～ 75% |
| 字节码 | 25% ~ 50% |
| 代码 | 🤏 |

并且更新只需要更新代码即可

如果是带前端的包，可以在字节码后面插入前端制品，取决于哪个变化概率比较大
| 层 | 大小 |
| --- | --- |
| 依赖 | 50% ～ 75% |
| 字节码 | 25% ~ 50% |
| 前端 | 1% ~ 5% |
| 代码 | 🤏 |


## 坑
#### uv.lock记录安装镜像源

当你使用 `UV_DEFAULT_INDEX` 环境变量或者 `uv.toml` 配置文件改变 `index-url` 配置时，uv 会将这个 `index-url` 记录到 lock 文件中，并在下一次执行 `sync --locked` 或 `sync --frozen` 的时候直接使用 lock 文件中的 `index-url`

<details>
<summary>示例文件</summary>

```toml

[[package]]
name = "aiofile"
version = "3.12.3"
source = { registry = "http://mirrors.home/pypi/simple" }
dependencies = [
    { name = "caio" },
]
sdist = { url = "http://mirrors.home/pypi/packages/14/31/edb06aabd8f8f0b56d659f30800795f40b93cba96be946ce179f6931e3a5/aiofile-3.12.3.tar.gz", hash = "sha256:caa6aa746b5e47e2165f7abd741b6415e49cf4d44fddc0f61844612cc3924d41" }
wheels = [
    { url = "http://mirrors.home/pypi/packages/4e/79/6e45e778c4c3cab39e0937b007b720c15f76c50c6453d153282d0fcc3588/aiofile-3.12.3-py3-none-any.whl", hash = "sha256:5c1bcc9e929c50834608e8cc1a4cc1d7503eb60c15a535b779fd39e2f372c017" },
]

```

</details>


正常情况下没有问题，只要你是用的公共镜像源能在任意位置访问就行。但下面的场景就会造成问题
- 使用的是内网自建缓存（我），但 Runner 不在内网
- 使用的是国内缓存，但尝试在 github runner 上构建
- 内网 Runner 无公网访问权限


因此只能将 `uv.lock` 加入 `.gitignore` 和 `.dockerignore`，让 Runner 生成自己的 uv.lock。

**但这样子会产生版本不一致的问题😶‍🌫️，目前没什么很好的解决方案**