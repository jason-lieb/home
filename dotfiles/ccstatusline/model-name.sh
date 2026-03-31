#!/bin/sh
model_id=$(jq -r '.model.id // ""')
case "$model_id" in
  "$ANTHROPIC_DEFAULT_OPUS_MODEL")   echo "Opus" ;;
  "$ANTHROPIC_DEFAULT_SONNET_MODEL") echo "Sonnet" ;;
  "$ANTHROPIC_DEFAULT_HAIKU_MODEL")  echo "Haiku" ;;
  *) echo "$model_id" ;;
esac
