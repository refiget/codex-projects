#!/usr/bin/env bash

DOWNLOADS="$HOME/Downloads"

# 路径定义
IMG="$DOWNLOADS/Images"
DOC="$DOWNLOADS/Documents"
VID="$DOWNLOADS/Videos"
ARC="$DOWNLOADS/Archives"
AUD="$DOWNLOADS/Audio"
COD="$DOWNLOADS/Code"
OTH="$DOWNLOADS/Others"

echo "📂 正在整理 $DOWNLOADS ..."

for file in "$DOWNLOADS"/*; do
  # 跳过目录，只整理文件
  if [ -d "$file" ]; then 
    continue
  fi

  # 获取文件扩展名（全部转换成小写）
  ext=$(echo "${file##*.}" | tr '[:upper:]' '[:lower:]')

  case "$ext" in
    jpg|jpeg|png|gif|bmp|svg|webp|heic)
      mv "$file" "$IMG/"
      echo "🖼 移动图片 → $(basename "$file")"
      ;;
    pdf|txt|md|doc|docx|ppt|pptx|xls|xlsx|csv)
      mv "$file" "$DOC/"
      echo "📄 移动文档 → $(basename "$file")"
      ;;
    mp4|mov|avi|mkv|flv|wmv)
      mv "$file" "$VID/"
      echo "🎬 移动视频 → $(basename "$file")"
      ;;
    zip|rar|7z|gz|tar)
      mv "$file" "$ARC/"
      echo "📦 移动压缩包 → $(basename "$file")"
      ;;
    mp3|wav|aac|flac|ogg)
      mv "$file" "$AUD/"
      echo "🎵 移动音频 → $(basename "$file")"
      ;;
    py|js|ts|cpp|c|java|html|css|json|sh)
      mv "$file" "$COD/"
      echo "💻 移动代码文件 → $(basename "$file")"
      ;;
    *)
      mv "$file" "$OTH/"
      echo "📦 其他文件 → $(basename "$file")"
      ;;
  esac
done

echo "✨ 整理完成！"
