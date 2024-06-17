echo "Setting system clock..."
if /sbin/rtc-read-offset; then
    echo "Done"
else
    echo "Failed"
fi
