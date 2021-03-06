# poyo-v
poyo-vはFPGAやASICに使えるRISC-Vソフトプロセッサです。誰でも容易に拡張・インプリメントできるインオーダ・スーパースカラプロセッサを目指してVerilog HDLで開発されています。

*Poyo-v is a RISC-V soft processor developed for FPGAs and ASICs. It is being developed in Verilog HDL aiming at a general-purpose in-order superscalar processor that anyone can easily expand its function.*

機能 |実装済 or まだ
--- |---
ISA |RISC-V (RV32IM)
乗除算命令（M） |✔
単精度浮動小数点演算（F） |まだ
倍精度浮動小数点演算（D） |まだ
アトミック命令（A） |まだ
圧縮命令（C） |まだ
パイプライン化 *pipeline* |✔
スーパースカラ化 *superscalar* |✔
キャッシュ *cache* |まだ
特権関係  *Privileged Architecture* |まだ
OS |まだ

## Running poyo-v on an FPGA
### 動作環境
- OS: Windows10 or Ubuntu18.04
- Vivado: 2018.3
- FPGAボード: [ZYBO Z7-10](http://akizukidenshi.com/catalog/g/gM-12552/)等（[ZYBO Z7-20](http://akizukidenshi.com/catalog/g/gM-12553/), [PYNQ-Z1](http://akizukidenshi.com/catalog/g/gM-13812/), [CMOD S7](http://akizukidenshi.com/catalog/g/gM-13487/)でも動作確認済。近年のXilinx社製FPGA搭載ボードであればだいたいどれでも動作可能と思われます。poyo-vは特定のIPに依存しないよう基本的に全てのモジュールがVerilog HDLのソースによって記述されています。）
- USB-シリアル変換モジュール: [FT232RL](http://akizukidenshi.com/catalog/g/gK-01977/)等

poyo-vをFPGA上で動かすためには、以下のような手順が必要です。

### 1. 本リポジトリをクローン
このリポジトリをローカルに持ってきます。
```
$ git clone https://github.com/ourfool/poyo-v.git
```

### 2. .tclの書き換え
`poyo-v/tcl/poyo-v_pipeline_3stage.tcl`のはじめに書かれた`set origin_dir "D:/Github/poyo-v/tcl"`を修正します。ローカル環境に合わせて`poyo-v/tcl`の場所を絶対パスで記述し直してください。注意点としてはWindows環境の場合にも`/`区切りのパスで記述してください。

### 3. プロジェクト作成
Vivadoを開き、上部タブの**Tools**→**Run Tcl Script**から`poyo-v/tcl/poyo-v_pipeline_3stage.tcl`ファイルを開くことで新規プロジェクトを作成します。

### 4. メモリデータパスの書き換え
RISC-Vプロセッサのメモリに読み込む.hexファイルのパスを環境に合わせて修正します。修正する箇所は、`poyo-v/src/pipeline_3stage/design/define.vh`内の`define MEM_DATA_PATH "D:/Github/poyo-v/software/Coremark_for_50MHz/"`です。ローカル環境に合わせて
`poyo-v/software/Coremark_for_50MHz/"`の場所を絶対パスで記述し直してください。

### 5. Bitstream生成・書き込み
各ファイルの修正完了後に、作成したVivadoプロジェクト上で、左端の**Flow Navigator**から**PROGRAM AND DEBUG**→**Generate Bitstream**を選択してBitstreamを生成します。完了したらPCとFPGAボードとを接続し、**Open Hardware Manager**から**Program device**を選択してFPGAボードへと書き込みます。

### 6. 動作確認
サンプルプログラムは組み込み向けベンチマークの[Coremark](https://www.eembc.org/coremark/)です。`poyo-v/src/pipeline_3stage/constraint/const.xdc`内で指定されたUART用端子（Pmod Header JEのje[0]、最右上側の端子）とGND端子（Pmod Header JEの左から2番目、上側の端子）とをUSB-シリアル変換モジュールのRX端子とGND端子へそれぞれ接続し、PCへUSBケーブルを介してつなぐことで、UART出力をPC上のシリアルターミナルソフト（Teraterm、gtkterm、Arduino IDE付属のターミナル等）で確認することができます。シリアルターミナルソフトのbaudrateは115200に設定してください。

<img src="https://ourfool.github.io/poyo-v/figs/poyo-v.jpg" width="600px">

各接続とターミナルソフトの設定を完了したら、動作確認をおこなうことができます。`poyo-v/src/pipeline_3stage/constraint/const.xdc`内で指定されたリセットボタン（btn[0]）を押すとプログラムが開始し、10秒ほどでシリアルターミナル上に完了のメッセージが表示されます。

<img src="https://ourfool.github.io/poyo-v/figs/poyo-v.png" width="600px">

## Creating an executable program file
poyo-v上で動作するプログラムを作るためには、以下のような手順が必要です。

### 1. コンパイラツールチェーンの用意
RISC-V RV32I向けの実行ファイルを生成するソフトウェアツールチェーンを用意します。gccの場合は[公式リポジトリ](https://github.com/riscv/riscv-gnu-toolchain)を参照してください。

### 2. メモリマップの設定
リンカスクリプト等を編集して、poyo-v向けのメモリマップ設定をおこないます。poyo-vにおいては以下のようなメモリマップを想定しています。

|アドレス |容量 |内容 |対応する.hexファイル |
|--- |--- |--- |--- |
|0x00000-0x07FFF |32KiB |なし |software/${各プログラムのフォルダ名}/code.hex |
|0x08000-0x0FFFF |32KiB |.text(ROM) |software/${各プログラムのフォルダ名}/code.hex |
|0x10000-0x17FFF |32KiB |.rodata + .data + .bss + .comment(RAM) |software/${各プログラムのフォルダ名}/data{0, 1, 2, 3}.hex |
|0x18000-0x1FFFF |32KiB |stack(RAM) |なし |
|0x20010 |. |hardware counter用アドレス |なし |
|0x20020 |. |uart送信用アドレス |なし |
|0x20030 |. |uart受信用アドレス |なし |
|0x20040 |. |汎用入力ピン用アドレス |なし |
|0x20050 |. |汎用出力ピン用アドレス |なし |


### 3. スタートアップルーチンの用意
スタートアップルーチンを作成します。

### 4. コード記述
動かしたいプログラムを記述します。

### 5. コンパイル
RISC-V RV32I向けの実行ファイルを生成します。可能であればIntel HEX等の形式に変換します。
 
### 6. .hex形式への変換
poyo-vで読み込むための.hex形式へと変換をおこないます。poyo-vの読み込めるcode.hexファイル形式は、一行あたり4byteのデータ×16384行（合計64KiB）のテキストファイルです。一行あたり16進数で8文字が書かれており、一つの命令を表しています。たとえば、`0080006f`という行の場合は

|[3]番地 |[2]番地 |[1]番地 |[0]番地 |
|:---: |:---: |:---: |:---: |
|00 |80 |00 |6F |

というバイトオーダで命令メモリへ格納されることになります。

すなわち命令メモリの中身は、

|番地 |格納されたデータ |
|--- |--- |
|0 |code.hexの1行目{7,8}番目文字 |
|1 |code.hexの1行目{5,6}番目文字 |
|2 |code.hexの1行目{3,4}番目文字 |
|3 |code.hexの1行目{1,2}番目文字 |
|4 |code.hexの2行目{7,8}番目文字 |
|5 |code.hexの2行目{5,6}番目文字 |
|6 |code.hexの2行目{3,4}番目文字 |
|7 |code.hexの2行目{1,2}番目文字 |
|. |. |
|. |. |
|. |. |
|n |code.hexの {n/4+1} 行目 {7-2x,8-2x(x≡n(mod 4))} 番目文字 |

となります。

一方、data{0, 1, 2, 3}.hexは、一行あたり1byteのデータ×8192行（4ファイル合計で32KiB）のテキストファイルです。

|[3]番地 |[2]番地 |[1]番地 |[0]番地 |
|:---: |:---: |:---: |:---: |
|data3.hexに記述された値 |data2.hexに記述された値 |data1.hexに記述された値 |data0.hexに記述された値 |

というようにデータメモリへ格納されることになります。

すなわちデータメモリの中身は、

|番地 |格納されたデータ |
|--- |--- |
|0 |data0.hexの1行目 |
|1 |data1.hexの1行目 |
|2 |data2.hexの1行目 |
|3 |data3.hexの1行目 |
|4 |data0.hexの2行目 |
|5 |data1.hexの2行目 |
|6 |data2.hexの2行目 |
|7 |data3.hexの2行目 |
|. |. |
|. |. |
|. |. |
|n |data{x}.hex (x≡n(mod 4)) の {n/4+1} 行目 |

となります。なお、poyo-vのデータメモリ（dmem.v）は実際には4つのインスタンスへと分割されて呼び出されており、それぞれのインスタンスが対応するファイルを読み込んでいます。
 
## Author
* **Ourfool in Saginomiya** -[homepage](http://www.saginomiya.xyz/)-

## License
This project is released under the MIT License - see the [LICENSE](LICENSE) file for details
