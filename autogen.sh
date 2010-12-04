./gitlog-to-changelog > ChangeLog
autoreconf -iv || exit 1
automake --add-missing
./configure --enable-maintainer-mode $@
