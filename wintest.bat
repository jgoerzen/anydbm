cd testsrc
ghc --make -package mtl HUnit -fallow-overlapping-instances -fallow-undecidable-instances -fglasgow-exts -cpp -o runtests.exe -i..\dist\build:..\src runtests.hs
cd ..
testsrc\runtests

