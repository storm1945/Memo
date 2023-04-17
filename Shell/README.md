# 循环
```sh
sum=0
for i in `seq 1 100`
do
    sum=$[$sum+$i]
    echo $i
done
echo $sum
```