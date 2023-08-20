# Dlang Attractor
Drawing an attractor in the programming language D [#dlang]

![Attractor 1](https://github.com/openkoder/dlang_attractor/blob/main/frame_10000_1.jpg?raw=true)
![Attractor 2](https://github.com/openkoder/dlang_attractor/blob/main/frame_10000_2.jpg?raw=true)


You can create a video from a set of images using the ffmpeg program.

**Here is a working example of such code:**
```
ffmpeg -f image2 -i frame_%04d.png -s 720x1280 -vcodec libx264 -preset slow -bf 0 -crf 18 -r 30 video_vo.mp4
```
