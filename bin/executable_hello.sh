#!/bin/bash 

echo 'おはようプロトコルを実行します'

# gcloud auth login && gcloud auth application-default login

gcloud auth login --update-adc

echo ''
echo 'dotfiles のドリフトを確認します'

if command -v chezmoi >/dev/null; then
  drift=$(chezmoi status)
  if [ -n "$drift" ]; then
    echo '⚠️  chezmoi 管理ファイルに差分があります:'
    echo "$drift"
    echo '→ 確認: chezmoi diff / 取り込み: chezmoi re-add <file> / 破棄: chezmoi apply'
  else
    echo '✅ dotfiles: ドリフトなし'
  fi
else
  echo 'chezmoi が見つかりません（スキップ）'
fi
