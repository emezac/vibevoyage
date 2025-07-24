mkdir -p /tmp/tmp
for file in ./*.html.erb; do
  base=$(basename "$file" .html.erb)
  cp "$file" "/tmp/tmp/$base.txt"
done

