echo "Saving system clock..."
if /sbin/rtc-save-offset; then
    echo "Done"
else
    echo "Failed"
fi
