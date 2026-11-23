# stoneship 

like a ship made from stone, this shall surely sink

### level zero hello world
```bash
make
./stsh prg/hello0.s hello0.txt
cat hello0.txt
```

### level one hello world
```bash
make
./stsh prg/hello1.s hello1
./hello1
```

### boot manually (using `xxd` and `cut`)
```bash
cut -d'#' -f1 stoneship.s | xxd -r -p > tmp.out
./tmp.out stoneship.s stsh
```

### EX IPSO AD IPSUM
```bash
./stsh stoneship.s stsh
```







