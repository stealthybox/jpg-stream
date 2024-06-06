all: build/jpeg.js

jpeg-9a/.libs/libjpeg.so: jpegsrc.v9a.tar
	tar -xvf jpegsrc.v9a.tar
	cd jpeg-9a && emconfigure ./configure && emmake make

build/jpeg.js: jpeg-9a/.libs/libjpeg.so src/*.h src/*.cc
	mkdir -p build/
	emcc --memory-init-file 0 \
			 --bind -Ijpeg-9a/ \
			 -s NO_FILESYSTEM=1 \
			 -s NO_BROWSER=1 \
			 -s DISABLE_EXCEPTION_CATCHING=1 \
			 -s PRECISE_I64_MATH=0 \
			 -s ALLOW_MEMORY_GROWTH=1 \
			 -O3 jpeg-9a/.libs/libjpeg.so src/*.cc -o build/jpeg.js
	echo "module.exports = Module;" >> build/jpeg.js

clean:
	rm -rf jpeg-9a/ build/


ORG := stealthybox
IMAGE := nix-env-emscripten
VERSION := 1.37.36

docker-image:
	docker build -t ${ORG}/${IMAGE}:${VERSION}-`docker info -f '{{.Architecture}}'` .

docker-push:
	docker push ${ORG}/${IMAGE}:${VERSION}-`docker info -f '{{.Architecture}}'`

docker-compile:
	docker run -it -v ./:/repo -w/repo --rm ${ORG}/${IMAGE}:${VERSION}-`docker info -f '{{.Architecture}}'` make all
