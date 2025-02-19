▼ソースビルド前の事前準備

・ビルドにはOpenSSLが必須だが、msiでインストール後に下記公式ドキュメントの手順に従い、
cmake .. -G "NMake Makefiles"　で実行すると、OPENSSL_ROOT_DIRが見つからないと言われる
https://docs.fluentbit.io/manual/installation/windows#compilation

・＜解決手順＞下記Issueの手順に従えばOK
https://github.com/fluent/fluent-bit/issues/9202

・下記を実行する
cd C:\
git clone https://github.com/microsoft/vcpkg.git
cd vcpkg && bootstrap-vcpkg.bat
.\vcpkg.exe integrate install
.\vcpkg.exe --triplet x64-windows-static install openssl

・上記処理で、PowerShell-7のzipファイルがダウンロードされているが、この中にpwsh.exeは含まれていない
・pwsh.exeが無くてもソースビルドは通ったが、ビルドログを見ると下記が出力される
'pwsh.exe' は、内部コマンドまたは外部コマンド、  操作可能なプログラムまたはバッチ ファイルとして認識されていません。

・このためPowerShell-7をmsiでインストールする
https://learn.microsoft.com/ja-jp/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.4#msi

>where pwsh.exe
C:\Program Files\PowerShell\7\pwsh.exe

▼OpenRTM-aistのfluentbit_streamビルド用に修正が必要
・Windows環境でのビルド時にデータ型でエラーになるためキャストするように修正する必要がある
・mpack/mpack.hで、「'mpack_write': 'extern "C"' リンケージで関数をオーバーロードすることはできません」の
  エラーが多数発生する。ここでエラーになった関数はOpenRTM-aistのビルドでは使用しないため、コメントアウトで対応させる。
・上記修正を fluent-bit-3.2.6-windows.patch として登録している

▼パッチの当て方
・OpenRTMビルドに必要なパッチを当てる
・ビルド用スクリプトはbatのため、この中から patchコマンドを実行できない
・このため、flb3110-build.batを修正し、FluentBitのソースv3.1.10.zipをダウンロード、展開した直後で処理を止める

---　22行目にexitを挿入する
if not exist %FLB_ZIP% (
  powershell wget -O %FLB_ZIP% https://github.com/fluent/fluent-bit/archive/refs/tags/%FLB_ZIP%
  powershell Expand-Archive .\%FLB_ZIP% -DestinationPath .\
)
exit /b  ←★ここ
cd fluent-bit-%FLB_VERSION%
---

・fluent-bit-3.2.6ディレクトリが展開されたらGit Bashを起動してpatchコマンドを実行する

$ ls
README.txt        fluent-bit-3.2.6/               v3.2.6.zip
flb326-build.bat  fluent-bit-3.2.6-windows.patch

$ patch -p1 -d fluent-bit-3.2.6 < fluent-bit-3.2.6-windows.patch
patching file include/fluent-bit/flb_input.h
patching file include/fluent-bit/flb_output.h
patching file lib/ctraces/lib/mpack/src/mpack/mpack.h
patching file lib/monkey/include/monkey/mk_core/external/winuio.h
patching file lib/monkey/include/monkey/mk_core/mk_dep_unistd.h
patching file lib/monkey/include/monkey/mk_scheduler.h
patching file lib/monkey/include/monkey/mk_stream.h
patching file lib/msgpack-c/include/msgpack/pack_template.h
patching file lib/msgpack-c/include/msgpack/sysdep.h

・この後、batファイルに挿入したexit行を削除してからコマンドプロンプトで実行する
・このbatファイルはダウンロードしたzipファイルが存在していたら展開したfluent-bit-3.2.6ディレクトリは
　削除しない仕様となっている。zipファイルを削除してしまった場合は、patchを当てなおす必要がある。

・ビルド結果をログファイルに出力し、「エラー」文字を検索してエラー数が０だったらビルドが成功している
> flb326-build.bat > 1.log 2>&1
