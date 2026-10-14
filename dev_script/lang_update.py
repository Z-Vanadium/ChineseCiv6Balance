from sys import argv
import re

ENGLISH_PATH = '../lang/english.xml'
ENGLISH_TAG = 'en_US'

# ⚠ 2026-10-15 用户指示（在 2026-10-14「只维护中/日/英」基础上进一步收窄）：
#    文案**只维护中文与英文** —— 本表因此**清空**（原含 8 种语言，上游 BBG 做法；
#    2026-10-14 曾缩到只剩日文，2026-10-15 起日文也不再同步）。
#    中文由**手写**维护（本脚本从不处理 chinese.xml），英文走下面的 ENGLISH_PATH。
#    lang/japanese.xml 等其余 9 个语言文件**保留、不回退、不删除**（日文仍在 CCB.modinfo 里加载），
#    只是不再新增/修改文案 —— 见工程内 AGENTS.md 的 Localization workflow。
#    要恢复上游行为请从 git 历史取回本文件，但别忘了同步 AGENTS.md 的规则。
FILES = {}

def write_file(tag, text, file, lang_tag):
    print(f"Process file {file}")
    with open(file, 'r', encoding='utf-8') as fd:
        txt = fd.read()
    f = re.findall(rf"""<Replace\s*Tag=\"{tag}\"\s*Language=\"[a-zA-Z_]+\">\s*<Text>(.*?)<\/Text>\s*<\/Replace>""", txt)
    assert len(f) < 2
    if f:
        txt = re.sub(
                rf"""\s*<Replace\s*Tag=\"{tag}\"\s*Language=\"[a-zA-Z_]+\">\s*<Text>.*?<\/Text>\s*<\/Replace>""",
                f"\n\t\t<Replace Tag=\"{tag}\" Language=\"{lang_tag}\">\n\t\t\t<Text>{text}</Text>\n\t\t</Replace>",
                txt,
        )
    else:
        txt = re.sub(
                rf"""\s*</LocalizedText>""",
                f"\n\t\t<Replace Tag=\"{tag}\" Language=\"{lang_tag}\">\n\t\t\t<Text>{text}</Text>\n\t\t</Replace>\n\t</LocalizedText>",
                txt,
        )
    print(f"Write file {file}")
    with open(file, 'w', encoding='utf-8') as fd:
        fd.write(txt)


def main():
    if len(argv) != 3:
        print(f"USAGE: {argv[0]} [Tag] [Text]")
        return
    tag = argv[1]
    text = argv[2]
    write_file(tag, text, ENGLISH_PATH, ENGLISH_TAG)
    # 2026-10-15：FILES 已清空（只维护中/英；中文手写、英文见上）→ 下面这个循环现在什么都不写。
    # 若以后把某个语言重新纳入维护范围，在这里把 (文件, 语言码) 加回去即可；
    # 那时写正文不再需要 [COLOR_RED]TO_TRANSLATE 前缀（本项目三个以上语言一律手写）。
    for k, v in FILES.items():
        write_file(tag, text, k, v)



if __name__ == '__main__':
    main()