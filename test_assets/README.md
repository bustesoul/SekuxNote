# SekuxNote 测试音频

本目录包含 SekuxNote 导入、批量转写和说话人识别测试所需的本地会议音频。音频文件默认被 `.gitignore` 忽略；仓库只应提交本说明和 `manifest.yaml`。

## 当前素材

| ID | 文件 | 场景 | 截取区间 | 标注说话人 | 许可 |
| --- | --- | --- | --- | ---: | --- |
| EN-AMI-1 | `en_ami_es2008a_5min.m4a` | 英文多人会议 | ES2008a 10:30–15:30 | 4 | CC BY 4.0 |
| EN-AMI-2 | `en_ami_es2008b_3min.m4a` | 英文多人会议 | ES2008b 09:30–12:30 | 4 | CC BY 4.0 |
| ZH-A4-1 | `zh_aishell4_6min.m4a` | 中文会议室阵列录音 | 20200706_L_R001S01C01 13:00–19:00，声道 3 | 7 | CC BY-SA 4.0 |

三段音频均为 AAC-LC、16 kHz、单声道 M4A。具体来源、校验值、截取参数和质量指标见 `manifest.yaml`。

## 许可与署名

- AMI 素材来自 [AMI Meeting Corpus](https://groups.inf.ed.ac.uk/ami/)，公开信号和转写按 [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) 使用。署名：AMI Meeting Corpus, University of Edinburgh et al.
- 中文素材来自 [AISHELL-4 / OpenSLR 111](https://openslr.org/111/)，按 [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) 使用。该截取和转码版本继续使用同一许可。
- 不要移除 `manifest.yaml` 中的来源、署名或许可信息。

## 质量检查

生成后已完成以下检查：

- FFmpeg 全文件解码无错误；
- 时长分别为 300、180 和 360 秒；
- AAC-LC、16 kHz、单声道；
- 无削波，峰值均低于 0 dBFS；
- AMI 窗口由官方说话人分段标注筛选；AISHELL-4 窗口由 TextGrid 标注筛选，包含多人轮替和重叠语音。

响度保留源录音特征，未做人为归一化，以覆盖真实会议录音电平差异。
