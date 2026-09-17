#!/usr/bin/env sh

ENDPOINT=$1
FROM_DIR=$2
OWNER=$3
PACKAGE_NAME=$4
VERSION=$5

upload() {
	FILE_PATH=$1
	FILE_NAME=$2

	UPLOAD_URL="$ENDPOINT/api/packages/$OWNER/generic/$PACKAGE_NAME/$VERSION/$FILE_NAME"

	echo "$FILE_PATH -> $UPLOAD_URL"
	curl --user $FORGEJO_USER:$FORGEJO_PASSWORD \
		--upload-file $FILE_PATH \
		$UPLOAD_URL
}

for f in $(find $FROM_DIR -mindepth 1 -maxdepth 1 ! -name "*.gz" ! -name "manifest.json")
do
	FILE_NAME=$(basename $f)
	if [ -f "$f" ] || [ "$FILE_NAME" = "Fumohouse.app" ]; then
		tar -C $FROM_DIR -czvf $f.tar.gz $FILE_NAME
		upload $f.tar.gz $FILE_NAME.tar.gz
	fi
done

for d in $(find $FROM_DIR/modules -mindepth 1 -maxdepth 1 -type d)
do
	SCOPE=$(basename $d)

	for f in $(find $FROM_DIR/modules/$SCOPE -maxdepth 1 -type f ! -name "*.gz")
	do
		MODULE_FILE_NAME=$(basename $f)
		gzip -kf $f
		upload $f.gz $SCOPE-$MODULE_FILE_NAME.gz
	done
done

# Upload the manifest last to indicate completion of release
upload $FROM_DIR/manifest.json manifest.json
