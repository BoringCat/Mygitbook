# UV包管理器使用经验 <!-- omit in toc -->

- [打包](#打包)
  - [Docker](#docker)
    - [优化层大小](#优化层大小)
  - [云函数等](#云函数等)
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

<br/>

这样子打出来镜像就会有
| 层 | 大小 |
| --- | --- |
| 依赖 | 50% ～ 75% |
| 字节码 | 25% ~ 50% |
| 代码 | 🤏 |

并且更新只需要更新代码即可

<br/>

如果是带前端的包，可以在字节码后面插入前端制品，取决于哪个变化概率比较大
| 层 | 大小 |
| --- | --- |
| 依赖 | 50% ～ 75% |
| 字节码 | 25% ~ 50% |
| 前端 | 1% ~ 5% |
| 代码 | 🤏 |


### 云函数等
我的习惯是使用docker打包，可以避免一堆权限/路径/依赖问题

```bash
docker build --output . .
```

<details>
<summary>Dockerfile</summary>

```dockerfile
# 1. 定义 uv 包镜像，指定版本
ARG UV_VERSION=0.12.6
FROM ghcr.io/astral-sh/uv:${UV_VERSION} AS uv

# 2. 定义运行时版本，建议从云函数编辑界面看/etc/os-relases，选用对应的版本
FROM centos:7 AS builder
SHELL [ "/bin/bash", "-euo", "pipefail", "-c" ]
WORKDIR /app

## 定义Python版本
ARG PYTHON_VERSION=3.9
ENV UV_LINK_MODE=copy UV_COMPILE_BYTECODE=0 UV_NO_DEV=1 UV_PYTHON=${PYTHON_VERSION}

# 3. 拷贝项目描述文件进去
COPY --from=uv /uv /uvx /bin/
COPY pyproject.toml README.md /app

# 4. 创建依赖文件并使用pip安装到 dist 目录
## 一些不能依赖动态链接的包需要安装二进制包，例如 cryptography 
RUN --mount=type=cache,target=/root/.cache/uv\
    --mount=type=cache,target=/root/.local/share/uv/python\
    set -x\
 && export UV_DEFAULT_INDEX UV_SYSTEM_CERTS\
 && uv export --format requirements.txt --no-dev --emit-index-url --no-editable --no-install-project > /tmp/requirements.txt\
 && uv pip install -r /tmp/requirements.txt -t /app/dist/ --only-binary cryptography,cffi,pycparser

# 5. 将代码完整拷贝到 dist 目录
## 因为一些云函数不支持调用包的函数，建议在src目录放一个 index.py 或 entrypoint.py 充当入口函数
COPY src/ /app/dist/

# 6. 打zip包
RUN set -x\
 && cd /app/dist/\
 && zip -9 -r /scf.zip . -x '**/__pycache__/**' -x '**/__pycache__/' -x '__pycache__/**' -x '__pycache__/'

# 7. 输出zip包
FROM scratch AS binaries
COPY --from=packager /scf.zip /
```

</details>

<br/>

另外还可以基于 `pyproject.toml` 的 `[dependency-groups]` 块，分层打包

例如：
```toml
[dependency-groups]
es = [
    "aiohttp~=3.9.5",
    "aiosignal~=1.3.1",
    "async-timeout~=4.0.3",
    "attrs~=23.2.0",
    "certifi~=2024.6.2",
    "elasticsearch[async]~=7.16.2",
    "frozenlist~=1.4.1",
    "idna~=3.7",
    "multidict~=6.0.5",
    "urllib3~=1.26.19",
    "yarl~=1.9.4",
]
```

```bash
docker build -f layout.dockerfile --build-args LAYOUT=es --output . .
```

<details>
<summary>layout.dockerfile</summary>

```dockerfile
# 1. 定义 uv 包镜像，指定版本
ARG UV_VERSION=0.12.6
FROM ghcr.io/astral-sh/uv:${UV_VERSION} AS uv

# 2. 定义运行时版本，建议从云函数编辑界面看/etc/os-relases，选用对应的版本
FROM centos:7 AS builder
SHELL [ "/bin/bash", "-euo", "pipefail", "-c" ]
WORKDIR /app
## 一些发行版可能没有默认安装zip，需要手动安装或使用python打包
RUN --mount=type=cache,target=/var/cache\
 && yum install -y zip\

## 定义Python版本
ARG PYTHON_VERSION=3.9
ENV UV_LINK_MODE=copy UV_COMPILE_BYTECODE=0 UV_NO_DEV=1 UV_PYTHON=${PYTHON_VERSION}

# 3. 拷贝项目描述文件进去
COPY --from=uv /uv /uvx /bin/
COPY pyproject.toml README.md /app

# 4. 创建层的依赖文件并使用pip安装到 dist 目录
## 一些不能依赖动态链接的包需要安装二进制包，例如 cryptography 
ARG LAYOUT
RUN --mount=type=cache,target=/root/.cache/uv\
    --mount=type=cache,target=/root/.local/share/uv/python\
    set -x\
 && export UV_DEFAULT_INDEX UV_SYSTEM_CERTS\
 && uv export --format requirements.txt --only-group "${LAYOUT}" --no-dev --emit-index-url --no-editable --no-install-project > /tmp/requirements.txt\
 && uv pip install -r /tmp/requirements.txt -t /app/dist/ --only-binary cryptography,cffi,pycparser

# 5. 打zip包
## 分开是为了在改zip参数的时候不需要重新安装
ARG LAYOUT
RUN set -x\
 && cd /app/dist/\
 && zip -9 -r /layout-${LAYOUT}.zip . -x '**/__pycache__/**' -x '**/__pycache__/' -x '__pycache__/**' -x '__pycache__/'

# 6. 输出zip包
FROM scratch AS binaries
ARG LAYOUT
COPY --from=packager /layout-${LAYOUT}.zip /
```

</details>

## 坑
#### uv.lock记录安装镜像源

当你使用 `UV_DEFAULT_INDEX` 环境变量或者 `uv.toml` 配置文件改变 `index-url` 配置时，uv 会将这个 `index-url` 记录到 lock 文件中，并在下一次执行 `sync --locked` 或 `sync --frozen` 的时候直接使用 lock 文件中的 `index-url`

<br/>

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

<br/>

正常情况下没有问题，只要你是用的公共镜像源能在任意位置访问就行。但下面的场景就会造成问题
- 使用的是内网自建缓存（我），但 Runner 不在内网
- 使用的是国内缓存，但尝试在 github runner 上构建
- 内网 Runner 无公网访问权限


因此只能将 `uv.lock` 加入 `.gitignore` 和 `.dockerignore`，让 Runner 生成自己的 uv.lock。

**但这样子会产生版本不一致的问题😶‍🌫️，目前没什么很好的解决方案**