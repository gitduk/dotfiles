#!/usr/bin/zsh

# 获取输入参数
text=$1

# 计算文本的长度
length=${#text}

# 计算装饰线的长度
line_length=$((length + 8))

# 生成装饰线
line=$(printf '#%.0s' {1..$line_length})

# 输出结果
echo $line
echo "### $text ###"
echo $line

