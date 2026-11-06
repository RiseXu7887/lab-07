# 遍历四个测试文件夹：Testcase1 到 Testcase4
for num in 1 2 3 4
do
    # 设置输入和输出文件夹的名称
    input_dir="Testcase${num}"
    output_dir="Testcase${num}Diff"

    # 删除旧的输出文件夹，确保每次运行结果一致
    rm -rf "$output_dir"

    # 遍历当前文件夹中所有以 .1.txt 结尾的文件
    for file1 in "$input_dir"/*.1.txt
    do
        # 如果没有找到文件，则跳过
        [ -f "$file1" ] || continue

        # 找到对应的.2.txt 文件
        file2="${file1%.1.txt}.2.txt"

        # 如果对应的第二个文件不存在，则跳过
        [ -f "$file2" ] || continue

        # 获取文件名，去掉文件夹路径
        filename="${file1##*/}"

        # 去掉末尾的.1.txt
        filename="${filename%.1.txt}"

        # 比较两个文件的内容，cmp -s 不输出内容，只通过退出状态判断是否相同
        # ! 表示取反，因此文件不同时才执行下面的代码
        if ! cmp -s "$file1" "$file2"
        then
            # 只有发现差异时才创建输出文件夹
            mkdir -p "$output_dir"

            # 使用 diff -u 生成差异报告
            diff -u "$file1" "$file2" > "$output_dir/${filename}Diff.txt"
        fi
    done
done

exit 0