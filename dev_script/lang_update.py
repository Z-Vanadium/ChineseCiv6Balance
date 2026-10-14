from sys import argv
import re

ENGLISH_PATH = '../lang/english.xml'
ENGLISH_TAG = 'en_US'

# ⚠ 2026-10-14 用户指示：文案只维护 中 / 日 / 英 三种语言。
#    本表原本含 8 种语言（上游 BBG 做法），现只保留日文 —— 中文由手写维护（本脚本从不处理 chinese.xml）。
#    要恢复上游行为请从 git 历史取回本文件，但别忘了同步 AGENTS.md 的规则。
FILES = {'../lang/japanese.xml': 'ja_JP',}

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
    # 2026-10-14：FILES 里现在只剩日文（维护语言），直接写正文，不再加 [COLOR_RED]TO_TRANSLATE 前缀。
    # 若以后把某个语言重新纳入维护范围，从 git 历史取回本文件的旧版本即可。
    for k, v in FILES.items():
        write_file(tag, text, k, v)



if __name__ == '__main__':
    main()