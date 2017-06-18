# 실행
```
// /Feh3 에서 h3부분은 원하는 파일 명으로
// vs2015 prompt

flex ex.l
bison -d -b y ex.y
cl y.tab.c lex.yy.c /Feh3 /link libfl.a

```