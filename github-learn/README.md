# 基本命令
<style>
table th:first-of-type {
    width: 6em;
}
table th:nth-of-type(2) {
    width: 80pt;
}
table th:nth-of-type(3) {
    width: 10cm;
}
</style>
|行为|命令|描述|
|:--:| :-- | :----- |
|初始化|init|在本地的当前目录里初始化git仓库|
|下载仓库|clone 地址|从网络上某个地址拷贝仓库(repository)到本地|
|查看当前状态|status|查看当前仓库的状态|
|查看不同|diff|查看当前状态和最新的commit之间不同的地方|
||diff 版本号1<br>版本号2|查看两个指定的版本之间不同的地方。这里的版本号指的是commit的hash值|
|添加文件|add -A|把文件添加进track|
|撤回修改的且还未stage的内容|checkout -- .|这里用小数点表示撤回所有修改|
|提交|commit -m "提交信息"|提交信息最好能体现更改了什么|
|删除未tracked|clean -xf|删除当前目录下所有没有track过的文件。不管它是否是.gitignore文件里面指定的文件夹和文件|
|查看提交记录|log|查看当前版本及之前的commit记录|
||reflog|	HEAD的变更记录|
|版本回退|reset --hard 版本号|回退到指定版本号的版本，该版本之后的修改都被删除。同时也是通过这个命令回到最新版本。需要reflog配合|

# Git关联Github
1. 本地配置用户名和邮箱\
`git config --global user.name "你的用户名"`\
`git config --global user.email "你的邮箱"`
2. 生成ssh key\
`ssh-keygen -t rsa -C "你的邮箱"`\
`clip < ~/.ssh/id_rsa.pub`
3. 打开Github,进入Settings,点击左边的 SSH and GPG keys ，将ssh key粘贴到右边的Key里面。
4. 测试一下吧，执行 `ssh -T git@github.com`
5. 运行 `git remote add origin 你复制的地址`
6. 执行 `git push -u origin master` 将本地仓库上传至Github的仓库并进行关联
7. commit后同步到Github上,执行 `git push`

参考:https://www.cnblogs.com/schaepher/p/5561193.html
