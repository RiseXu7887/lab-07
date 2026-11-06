# 记录是否所有 Testcase 都通过，0表示全部通过，1表示至少有一个失败
all_failed=0

# 遍历四个 Testcase 文件夹
for num in 1 2 3 4
do
    # 设置输入和输出文件夹名称
    input_dir="Testcase${num}"
    output_dir="Testcase${num}Diff"

    # 记录当前 Testcase 是否正确，1表示正确，0表示错误
    case_pass=1

    # 记录当前 Testcase 是否存在不同的文件对，0表示没有差异，1表示存在差异
    has_diff=0

    # 遍历所有.1.txt 文件
    for file1 in "$input_dir"/*.1.txt
    do
        # 如果没有匹配的文件，则跳过
        [ -f "$file1" ] || continue

        # 找到对应的.2.txt 文件
        file2="${file1%.1.txt}.2.txt"

        # 如果第二个文件不存在，标记失败
        if [ ! -f "$file2" ]
        then
            case_pass=0
            continue
        fi

        # 提取文件名，去掉目录路径
        filename="${file1##*/}"

        # 去掉末尾的 .1.txt
        filename="${filename%.1.txt}"

        # 确定应该存在的差异报告路径
        output_file="$output_dir/${filename}Diff.txt"

        # 比较原始的两个文件
        if cmp -s "$file1" "$file2"
        then
            # 两个文件相同，不应该有差异报告
            if [ -e "$output_file" ]
            then
                case_pass=0
            fi
        else
            # 两个文件不同，应该存在差异报告
            has_diff=1

            # 检查差异报告是否存在
            if [ ! -f "$output_file" ]
            then
                case_pass=0
            else
                # 比较实际报告与正确的 diff -u 结果
                # tail -n +3 跳过前两行文件名和时间戳
                # <(...) 将命令输出当作可读取的输入
                # cmp -s 静默比较两边内容
                if ! cmp -s \
                    <(diff -u "$file1" "$file2" | tail -n +3) \
                    <(tail -n +3 "$output_file")
                then
                    case_pass=0
                fi
            fi
        fi
    done

    # 如果存在不同文件，必须有 Diff 文件夹
    if [ "$has_diff" -eq 1 ] && [ ! -d "$output_dir" ]
    then
        case_pass=0
    fi

    # 如果所有文件都相同，不应该有 Diff 文件夹
    if [ "$has_diff" -eq 0 ] && [ -e "$output_dir" ]
    then
        case_pass=0
    fi

    # 检查是否存在多余或不合法的输出文件
    if [ -d "$output_dir" ]
    then
        for report in "$output_dir"/*
        do
            # 没有匹配文件时跳过
            [ -e "$report" ] || continue

            # 输出目录内只能有普通文件
            if [ ! -f "$report" ]
            then
                case_pass=0
                continue
            fi

            # 获取报告文件名
            report_name="${report##*/}"

            # 判断文件名是否以 Diff.txt 结尾
            case "$report_name" in
                *Diff.txt)
                    base="${report_name%Diff.txt}"
                    ;;
                *)
                    case_pass=0
                    continue
                    ;;
            esac

            # 检查报告是否对应真实且有差异的文件对
            first="$input_dir/${base}.1.txt"
            second="$input_dir/${base}.2.txt"

            if [ ! -f "$first" ] || [ ! -f "$second" ]
            then
                case_pass=0
            elif cmp -s "$first" "$second"
            then
                # 相同文件不应该存在差异报告
                case_pass=0
            fi
        done
    fi

    # 输出当前 Testcase 的检查结果
    if [ "$case_pass" -eq 1 ]
    then
        echo "Testcase${num}: PASS"
    else
        echo "Testcase${num}: FAIL"
        all_failed=1
    fi
done

# 全部通过则退出状态为0，存在失败则退出状态为1
exit "$all_failed"