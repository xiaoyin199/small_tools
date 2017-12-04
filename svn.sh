#!/bin/bash

## svn的一些快捷操作

## 定义svn仓库目录
svnRootPath='/file/svnroot/'
## 转移路径下面有地方用到
svnEscapeRootPath='\/file\/svnroot\/'
## 定义web发布目录，钩子程序执行位置
webRootPath='/file/web/dynamic/'
## 定义需要排除不处理的项目
ignoreProject=(bakconf conf)
 
## 参数都转换为小写处理
## 第一个参数动作
action=$(echo $1 | tr '[A-Z]' '[a-z]')
## 第二个参数项目目录名,all
project=$(echo $2 | tr '[A-Z]' '[a-z]')
## 修改的具体操作add,del,edit
operate=$(echo $3 | tr '[A-Z]' '[a-z]')
## 用户名
username=$(echo $4 | tr '[A-Z]' '[a-z]')
## 密码
password=$5
## 设置用户的权限rw，r，只接受rw，r两个参数
authority=$6
## 是否输出字符
showStr='del'

## 初始化变量
function initializeVariable() {
    ## 项目路径
    svnProjectPath=$svnRootPath$project
    ## 配置文件路径
    svnservePath=$svnProjectPath'/conf/svnserve.conf'
    authzPath=$svnProjectPath'/conf/authz'
    passwdPath=$svnProjectPath'/conf/passwd'
}
## 自动运行初始化变量
initializeVariable

## 脚本运行判断第六个参数，权限参数是否正确
if [[ -z $authority || $authority = 'rw' ]]; then
    authority='rw'
elif [[ $authority = 'r' ]]; then
    authority='r'
else
    echo "authority parameters is error!"
fi

## 新建SVN项目
function create() {
    if [[ -d $svnProjectPath ]]; then
        echo "The project already exists!"
    else
        # 项目参数不能为空，-n非空串为真，-z空串为真
        if [[ -z $project ]]; then
            echo "project parameters is error!"
        elif [[ $project = 'all' ]]; then
            echo "Keyword can not as a parameter"
        else
            svnadmin create $svnProjectPath
            initSvnConfig
        fi
    fi
}

## 管理SVN项目，用户权限
function update() {
    if [[ $project = 'all' ]]; then
        if [[ -z $username ]]; then
            echo "username parameters is error!"
        else
            handelAll
        fi
    elif [[ ! -d $svnProjectPath ]]; then
        echo "The project does not exists!"
    else
        if [[ -z $username ]]; then
            echo "username parameters is error!"
        else
            handelOperate
        fi
    fi
}

## 处理所有项目
function handelAll() {
    projectArr=$(ls $svnRootPath)
    for p in $projectArr; do
        if [[ ${ignoreProject[@]} =~ $p ]] ; then
            echo "${p} project has been ignored!"
        else
            project=$p
            initializeVariable
            handelOperate
        fi
    done
}

## 处理的具体操作add,del,edit
function handelOperate() {
    case $operate in
        add)
        addUser
        ;;

        edit)
        editUser
        ;;

        del)
        delUser
        ;;

        *)
        echo "Operate command parameter error!"
        ;;
    esac
}

## 增加用户，设置权限，密码
function addUser() {
    if [[ -z $password ]]; then
        echo "password parameters is error!"
    else
        showStr='add'
        delUser
        echo "${username} = ${authority}" >> $authzPath
        echo "${username} = ${password}" >> $passwdPath
        echo "${project} project has been executed successfully!"
    fi
}

## 删除用户
function delUser() {
    sed -i "/${username} =/d" $authzPath
    sed -i "/${username} =/d" $passwdPath
    if [[ $showStr = 'del' ]]; then
        echo "${project} project has been executed successfully!"
    fi
}

## 编辑用户，编辑权限、密码
function editUser() {
    if [[ -z $possword ]]; then
        echo "password parameters is error!"
    else
        delUser
        addUser
    fi
}

## 初始化svn配置信息
function initSvnConfig() {
    sed -i "s/# anon-access = read/anon-access = none/" $svnservePath
    sed -i "s/# auth-access = write/auth-access = write/" $svnservePath
    sed -i "s/# password-db = passwd/password-db = passwd/" $svnservePath
    sed -i "s/# authz-db = authz/authz-db = authz/" $svnservePath
    sed -i "s/# realm = My First Repository/realm = ${svnEscapeRootPath}${project}/" $svnservePath
    echo -e "\n[/]" >> $authzPath
}

## 根据参数执行响应动作
case $action in
    create)
    create
    ;;

    update)
    update
    ;;

    *)
    echo "Command parameter error!"
    ;;
esac
