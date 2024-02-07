set filename=readme
REM export the images to the media folder
pandoc -s "%filename%.docx" -t gfm -o "%filename%.md" --extract-media="." --self-contained --wrap=none 
REM export the markdown file using relative path for images
REM pandoc -s "%filename%.docx" -t gfm -o "%filename%.md" --wrap=none 