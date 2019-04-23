# poyo-v
poyo-vはFPGAやASICに使えるRISC-Vソフトプロセッサです。誰でも容易に拡張・インプリメントできるインオーダ・スーパースカラプロセッサを目指してVerilog HDLで開発されています。

*Poyo-v is a RISC-V soft processor developed for FPGAs and ASICs. It is being developed in Verilog HDL aiming at a general-purpose in-order superscalar processor which anyone can easily extend / implement.*

機能 | 実装済 or まだ
--- | ---
ISA | RISC-V (RV32I)
乗除算命令（M） |まだ
単精度浮動小数点演算（F） |まだ
アトミック命令（A） |まだ
パイプライン化 *pipeline* |✔
スーパースカラ化 *superscalar* |まだ
キャッシュ *cache* |まだ
特権関係  *Privileged Architecture* |まだ
OS |まだ

## Running poyo-v on an FPGA
### 動作環境
- OS: Windows10 or Ubuntu18.04
- Vivado: 2018.3
- FPGAボード: ZYBO Z7-10

### チュートリアル
poyo-vをFPGA上で動かすためには、以下のような手順が必要です。

#### 1. 本リポジトリをクローン
このリポジトリをローカルに持ってきます。
```
$ git clone https://github.com/ourfool/poyo-v.git
```

#### 2. .tclの書き換え
`poyo-v/tcl/poyo-v_pipeline_3stage.tcl`のはじめに書かれた`set origin_dir "D:/Github/poyo-v/tcl"`を修正します。ローカル環境に合わせて`poyo-v/tcl`の場所を絶対パスで記述し直してください。注意点としてはWindows環境の場合にも`/`区切りのパスで記述してください。

#### 3. プロジェクト作成
Vivadoを開き、上部タブの**Tools**→**Run Tcl Script**から`poyo-v/tcl/poyo-v_pipeline_3stage.tcl`ファイルを開くことで新規プロジェクトを作成します。

#### 4. メモリデータパスの書き換え
RISC-Vプロセッサのメモリに読み込む.hexファイルのパスを環境に合わせて修正します。修正するファイルは、`poyo-v/tcl/poyo-v_pipeline_3stage.tcl`

## Example
 
## Author
* **Ourfool in Saginomiya** -[homepage](http://www.saginomiya.xyz/)-

## License
This project is licensed under the Apache-2.0 License - see the [LICENSE](LICENSE) file for details
