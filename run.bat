rmdir /s/q run
xcopy src run /e/i
copy z_new_o\make.bat run\make.bat
cd run
make run_full