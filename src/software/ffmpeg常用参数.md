# FFMPEG常用参数 <!-- omit in toc -->

- [音频](#音频)
- [视频](#视频)
  - [切割](#切割)
  - [转gif](#转gif)
  - [Nvidia h264](#nvidia-h264)
  - [Nvidia h265](#nvidia-h265)
  - [倍速](#倍速)
  - [慢速](#慢速)

### 音频
```bash
-c:a copy
```
```bash
-c:a acc -b:a 192K
```

### 视频
#### 切割
```bash
-ss ${mm:ss.SSS} ...... -t ${duration}
```

#### 转gif
```bash
-c:v gif -vf "split[s1][s2];[s1]trim=start_frame=0:end_frame=29,palettegen[p];[s2][p]paletteuse"
```

#### Nvidia h264
```bash
-c:v h264_nvenc -vsync 0 -rc:v vbr_hq -cq:v 28 -b:v 0 -profile:v main
```

<details>
<summary>详细参数</summary>

```
Encoder h264_nvenc [NVIDIA NVENC H.264 encoder]:
    General capabilities: dr1 delay hardware 
    Threading capabilities: none
    Supported hardware devices: cuda cuda d3d11va d3d11va 
    Supported pixel formats: yuv420p nv12 p010le yuv444p p016le yuv444p16le bgr0 bgra rgb0 rgba x2rgb10le x2bgr10le gbrp gbrp16le cuda d3d11
h264_nvenc AVOptions:
  -preset            <int>        E..V....... Set the encoding preset (from 0 to 18) (default p4)
     default         0            E..V....... 
     slow            1            E..V....... hq 2 passes
     medium          2            E..V....... hq 1 pass
     fast            3            E..V....... hp 1 pass
     hp              4            E..V....... 
     hq              5            E..V....... 
     bd              6            E..V....... 
     ll              7            E..V....... low latency
     llhq            8            E..V....... low latency hq
     llhp            9            E..V....... low latency hp
     lossless        10           E..V....... 
     losslesshp      11           E..V....... 
     p1              12           E..V....... fastest (lowest quality)
     p2              13           E..V....... faster (lower quality)
     p3              14           E..V....... fast (low quality)
     p4              15           E..V....... medium (default)
     p5              16           E..V....... slow (good quality)
     p6              17           E..V....... slower (better quality)
     p7              18           E..V....... slowest (best quality)
  -tune              <int>        E..V....... Set the encoding tuning info (from 1 to 4) (default hq)
     hq              1            E..V....... High quality
     ll              2            E..V....... Low latency
     ull             3            E..V....... Ultra low latency
     lossless        4            E..V....... Lossless
  -profile           <int>        E..V....... Set the encoding profile (from 0 to 3) (default main)
     baseline        0            E..V....... 
     main            1            E..V....... 
     high            2            E..V....... 
     high444p        3            E..V....... 
  -level             <int>        E..V....... Set the encoding level restriction (from 0 to 62) (default auto)
     auto            0            E..V....... 
     1               10           E..V....... 
     1.0             10           E..V....... 
     1b              9            E..V....... 
     1.0b            9            E..V....... 
     1.1             11           E..V....... 
     1.2             12           E..V....... 
     1.3             13           E..V....... 
     2               20           E..V....... 
     2.0             20           E..V....... 
     2.1             21           E..V....... 
     2.2             22           E..V....... 
     3               30           E..V....... 
     3.0             30           E..V....... 
     3.1             31           E..V....... 
     3.2             32           E..V....... 
     4               40           E..V....... 
     4.0             40           E..V....... 
     4.1             41           E..V....... 
     4.2             42           E..V....... 
     5               50           E..V....... 
     5.0             50           E..V....... 
     5.1             51           E..V....... 
     5.2             52           E..V....... 
     6.0             60           E..V....... 
     6.1             61           E..V....... 
     6.2             62           E..V....... 
  -rc                <int>        E..V....... Override the preset rate-control (from -1 to INT_MAX) (default -1)
     constqp         0            E..V....... Constant QP mode
     vbr             1            E..V....... Variable bitrate mode
     cbr             2            E..V....... Constant bitrate mode
     vbr_minqp       8388609      E..V....... Variable bitrate mode with MinQP (deprecated)
     ll_2pass_quality 8388609      E..V....... Multi-pass optimized for image quality (deprecated)
     ll_2pass_size   8388610      E..V....... Multi-pass optimized for constant frame size (deprecated)
     vbr_2pass       8388609      E..V....... Multi-pass variable bitrate mode (deprecated)
     cbr_ld_hq       8388610      E..V....... Constant bitrate low delay high quality mode
     cbr_hq          8388610      E..V....... Constant bitrate high quality mode
     vbr_hq          8388609      E..V....... Variable bitrate high quality mode
  -rc-lookahead      <int>        E..V....... Number of frames to look ahead for rate-control (from 0 to INT_MAX) (default 0)
  -surfaces          <int>        E..V....... Number of concurrent surfaces (from 0 to 64) (default 0)
  -cbr               <boolean>    E..V....... Use cbr encoding mode (default false)
  -2pass             <boolean>    E..V....... Use 2pass encoding mode (default auto)
  -gpu               <int>        E..V....... Selects which NVENC capable GPU to use. First GPU is 0, second is 1, and so on. (from -2 to INT_MAX) (default any)
     any             -1           E..V....... Pick the first device available
     list            -2           E..V....... List the available devices
  -rgb_mode          <int>        E..V....... Configure how nvenc handles packed RGB input. (from 0 to INT_MAX) (default yuv420)
     yuv420          1            E..V....... Convert to yuv420
     yuv444          2            E..V....... Convert to yuv444
     disabled        0            E..V....... Disables support, throws an error.
  -delay             <int>        E..V....... Delay frame output by the given amount of frames (from 0 to INT_MAX) (default INT_MAX)
  -no-scenecut       <boolean>    E..V....... When lookahead is enabled, set this to 1 to disable adaptive I-frame insertion at scene cuts (default false)
  -forced-idr        <boolean>    E..V....... If forcing keyframes, force them as IDR frames. (default false)
  -b_adapt           <boolean>    E..V....... When lookahead is enabled, set this to 0 to disable adaptive B-frame decision (default true)
  -spatial-aq        <boolean>    E..V....... set to 1 to enable Spatial AQ (default false)
  -spatial_aq        <boolean>    E..V....... set to 1 to enable Spatial AQ (default false)
  -temporal-aq       <boolean>    E..V....... set to 1 to enable Temporal AQ (default false)
  -temporal_aq       <boolean>    E..V....... set to 1 to enable Temporal AQ (default false)
  -zerolatency       <boolean>    E..V....... Set 1 to indicate zero latency operation (no reordering delay) (default false)
  -nonref_p          <boolean>    E..V....... Set this to 1 to enable automatic insertion of non-reference P-frames (default false)
  -strict_gop        <boolean>    E..V....... Set 1 to minimize GOP-to-GOP rate fluctuations (default false)
  -aq-strength       <int>        E..V....... When Spatial AQ is enabled, this field is used to specify AQ strength. AQ strength scale is from 1 (low) - 15 (aggressive) (from 1 to 15) (default 8)
  -cq                <float>      E..V....... Set target quality level (0 to 51, 0 means automatic) for constant quality mode in VBR rate control (from 0 to 51) (default 0)
  -aud               <boolean>    E..V....... Use access unit delimiters (default false)
  -bluray-compat     <boolean>    E..V....... Bluray compatibility workarounds (default false)
  -init_qpP          <int>        E..V....... Initial QP value for P frame (from -1 to 51) (default -1)
  -init_qpB          <int>        E..V....... Initial QP value for B frame (from -1 to 51) (default -1)
  -init_qpI          <int>        E..V....... Initial QP value for I frame (from -1 to 51) (default -1)
  -qp                <int>        E..V....... Constant quantization parameter rate control method (from -1 to 51) (default -1)
  -qp_cb_offset      <int>        E..V....... Quantization parameter offset for cb channel (from -12 to 12) (default 0)
  -qp_cr_offset      <int>        E..V....... Quantization parameter offset for cr channel (from -12 to 12) (default 0)
  -weighted_pred     <int>        E..V....... Set 1 to enable weighted prediction (from 0 to 1) (default 0)
  -coder             <int>        E..V....... Coder type (from -1 to 2) (default default)
     default         -1           E..V....... 
     auto            0            E..V....... 
     cabac           1            E..V....... 
     cavlc           2            E..V....... 
     ac              1            E..V....... 
     vlc             2            E..V....... 
  -b_ref_mode        <int>        E..V....... Use B frames as references (from -1 to 2) (default -1)
     disabled        0            E..V....... B frames will not be used for reference
     each            1            E..V....... Each B frame will be used for reference
     middle          2            E..V....... Only (number of B frames)/2 will be used for reference
  -a53cc             <boolean>    E..V....... Use A53 Closed Captions (if available) (default true)
  -dpb_size          <int>        E..V....... Specifies the DPB size used for encoding (0 means automatic) (from 0 to INT_MAX) (default 0)
  -multipass         <int>        E..V....... Set the multipass encoding (from 0 to 2) (default disabled)
     disabled        0            E..V....... Single Pass
     qres            1            E..V....... Two Pass encoding is enabled where first Pass is quarter resolution
     fullres         2            E..V....... Two Pass encoding is enabled where first Pass is full resolution
  -ldkfs             <int>        E..V....... Low delay key frame scale; Specifies the Scene Change frame size increase allowed in case of single frame VBV and CBR (from 0 to 255) (default 0)
  -extra_sei         <boolean>    E..V....... Pass on extra SEI data (e.g. a53 cc) to be included in the bitstream (default true)
  -udu_sei           <boolean>    E..V....... Pass on user data unregistered SEI if available (default false)
  -intra-refresh     <boolean>    E..V....... Use Periodic Intra Refresh instead of IDR frames (default false)
  -single-slice-intra-refresh <boolean>    E..V....... Use single slice intra refresh (default false)
  -max_slice_size    <int>        E..V....... Maximum encoded slice size in bytes (from 0 to INT_MAX) (default 0)
  -constrained-encoding <boolean>    E..V....... Enable constrainedFrame encoding where each slice in the constrained picture is independent of other slices (default false)
  -lookahead_level   <int>        E..V....... Specifies the lookahead level. Higher level may improve quality at the expense of performance. (from -1 to 15) (default -1)
     auto            15           E..V....... 
     0               0            E..V....... 
     1               1            E..V....... 
     2               2            E..V....... 
     3               3            E..V....... 


```

</details>

#### Nvidia h265
```bash
-c:v hevc_nvenc -vsync 0 -rc:v vbr_hq -qmin:v 22 -qmax:v 28 -b:v 0 -profile:v main
```

<details>
<summary>详细参数</summary>

```
Encoder hevc_nvenc [NVIDIA NVENC hevc encoder]:
    General capabilities: dr1 delay hardware 
    Threading capabilities: none
    Supported hardware devices: cuda cuda d3d11va d3d11va 
    Supported pixel formats: yuv420p nv12 p010le yuv444p p016le yuv444p16le bgr0 bgra rgb0 rgba x2rgb10le x2bgr10le gbrp gbrp16le cuda d3d11
hevc_nvenc AVOptions:
  -preset            <int>        E..V....... Set the encoding preset (from 0 to 18) (default p4)
     default         0            E..V....... 
     slow            1            E..V....... hq 2 passes
     medium          2            E..V....... hq 1 pass
     fast            3            E..V....... hp 1 pass
     hp              4            E..V....... 
     hq              5            E..V....... 
     bd              6            E..V....... 
     ll              7            E..V....... low latency
     llhq            8            E..V....... low latency hq
     llhp            9            E..V....... low latency hp
     lossless        10           E..V....... lossless
     losslesshp      11           E..V....... lossless hp
     p1              12           E..V....... fastest (lowest quality)
     p2              13           E..V....... faster (lower quality)
     p3              14           E..V....... fast (low quality)
     p4              15           E..V....... medium (default)
     p5              16           E..V....... slow (good quality)
     p6              17           E..V....... slower (better quality)
     p7              18           E..V....... slowest (best quality)
  -tune              <int>        E..V....... Set the encoding tuning info (from 1 to 5) (default hq)
     hq              1            E..V....... High quality
     uhq             5            E..V....... Ultra high quality
     ll              2            E..V....... Low latency
     ull             3            E..V....... Ultra low latency
     lossless        4            E..V....... Lossless
  -profile           <int>        E..V....... Set the encoding profile (from 0 to 4) (default main)
     main            0            E..V....... 
     main10          1            E..V....... 
     rext            2            E..V....... 
  -level             <int>        E..V....... Set the encoding level restriction (from 0 to 186) (default auto)
     auto            0            E..V....... 
     1               30           E..V....... 
     1.0             30           E..V....... 
     2               60           E..V....... 
     2.0             60           E..V....... 
     2.1             63           E..V....... 
     3               90           E..V....... 
     3.0             90           E..V....... 
     3.1             93           E..V....... 
     4               120          E..V....... 
     4.0             120          E..V....... 
     4.1             123          E..V....... 
     5               150          E..V....... 
     5.0             150          E..V....... 
     5.1             153          E..V....... 
     5.2             156          E..V....... 
     6               180          E..V....... 
     6.0             180          E..V....... 
     6.1             183          E..V....... 
     6.2             186          E..V....... 
  -tier              <int>        E..V....... Set the encoding tier (from 0 to 1) (default main)
     main            0            E..V....... 
     high            1            E..V....... 
  -rc                <int>        E..V....... Override the preset rate-control (from -1 to INT_MAX) (default -1)
     constqp         0            E..V....... Constant QP mode
     vbr             1            E..V....... Variable bitrate mode
     cbr             2            E..V....... Constant bitrate mode
     vbr_minqp       8388609      E..V....... Variable bitrate mode with MinQP (deprecated)
     ll_2pass_quality 8388609      E..V....... Multi-pass optimized for image quality (deprecated)
     ll_2pass_size   8388610      E..V....... Multi-pass optimized for constant frame size (deprecated)
     vbr_2pass       8388609      E..V....... Multi-pass variable bitrate mode (deprecated)
     cbr_ld_hq       8388610      E..V....... Constant bitrate low delay high quality mode
     cbr_hq          8388610      E..V....... Constant bitrate high quality mode
     vbr_hq          8388609      E..V....... Variable bitrate high quality mode
  -rc-lookahead      <int>        E..V....... Number of frames to look ahead for rate-control (from 0 to INT_MAX) (default 0)
  -surfaces          <int>        E..V....... Number of concurrent surfaces (from 0 to 64) (default 0)
  -cbr               <boolean>    E..V....... Use cbr encoding mode (default false)
  -2pass             <boolean>    E..V....... Use 2pass encoding mode (default auto)
  -gpu               <int>        E..V....... Selects which NVENC capable GPU to use. First GPU is 0, second is 1, and so on. (from -2 to INT_MAX) (default any)
     any             -1           E..V....... Pick the first device available
     list            -2           E..V....... List the available devices
  -rgb_mode          <int>        E..V....... Configure how nvenc handles packed RGB input. (from 0 to INT_MAX) (default yuv420)
     yuv420          1            E..V....... Convert to yuv420
     yuv444          2            E..V....... Convert to yuv444
     disabled        0            E..V....... Disables support, throws an error.
  -delay             <int>        E..V....... Delay frame output by the given amount of frames (from 0 to INT_MAX) (default INT_MAX)
  -no-scenecut       <boolean>    E..V....... When lookahead is enabled, set this to 1 to disable adaptive I-frame insertion at scene cuts (default false)
  -forced-idr        <boolean>    E..V....... If forcing keyframes, force them as IDR frames. (default false)
  -spatial_aq        <boolean>    E..V....... set to 1 to enable Spatial AQ (default false)
  -spatial-aq        <boolean>    E..V....... set to 1 to enable Spatial AQ (default false)
  -temporal_aq       <boolean>    E..V....... set to 1 to enable Temporal AQ (default false)
  -temporal-aq       <boolean>    E..V....... set to 1 to enable Temporal AQ (default false)
  -zerolatency       <boolean>    E..V....... Set 1 to indicate zero latency operation (no reordering delay) (default false)
  -nonref_p          <boolean>    E..V....... Set this to 1 to enable automatic insertion of non-reference P-frames (default false)
  -strict_gop        <boolean>    E..V....... Set 1 to minimize GOP-to-GOP rate fluctuations (default false)
  -aq-strength       <int>        E..V....... When Spatial AQ is enabled, this field is used to specify AQ strength. AQ strength scale is from 1 (low) - 15 (aggressive) (from 1 to 15) (default 8)
  -cq                <float>      E..V....... Set target quality level (0 to 51, 0 means automatic) for constant quality mode in VBR rate control (from 0 to 51) (default 0)
  -aud               <boolean>    E..V....... Use access unit delimiters (default false)
  -bluray-compat     <boolean>    E..V....... Bluray compatibility workarounds (default false)
  -init_qpP          <int>        E..V....... Initial QP value for P frame (from -1 to 51) (default -1)
  -init_qpB          <int>        E..V....... Initial QP value for B frame (from -1 to 51) (default -1)
  -init_qpI          <int>        E..V....... Initial QP value for I frame (from -1 to 51) (default -1)
  -qp                <int>        E..V....... Constant quantization parameter rate control method (from -1 to 51) (default -1)
  -qp_cb_offset      <int>        E..V....... Quantization parameter offset for cb channel (from -12 to 12) (default 0)
  -qp_cr_offset      <int>        E..V....... Quantization parameter offset for cr channel (from -12 to 12) (default 0)
  -weighted_pred     <int>        E..V....... Set 1 to enable weighted prediction (from 0 to 1) (default 0)
  -b_ref_mode        <int>        E..V....... Use B frames as references (from -1 to 2) (default -1)
     disabled        0            E..V....... B frames will not be used for reference
     each            1            E..V....... Each B frame will be used for reference
     middle          2            E..V....... Only (number of B frames)/2 will be used for reference
  -a53cc             <boolean>    E..V....... Use A53 Closed Captions (if available) (default true)
  -s12m_tc           <boolean>    E..V....... Use timecode (if available) (default true)
  -dpb_size          <int>        E..V....... Specifies the DPB size used for encoding (0 means automatic) (from 0 to INT_MAX) (default 0)
  -multipass         <int>        E..V....... Set the multipass encoding (from 0 to 2) (default disabled)
     disabled        0            E..V....... Single Pass
     qres            1            E..V....... Two Pass encoding is enabled where first Pass is quarter resolution
     fullres         2            E..V....... Two Pass encoding is enabled where first Pass is full resolution
  -highbitdepth      <boolean>    E..V....... Enable 10 bit encode for 8 bit input (default false)
  -ldkfs             <int>        E..V....... Low delay key frame scale; Specifies the Scene Change frame size increase allowed in case of single frame VBV and CBR (from 0 to 255) (default 0)
  -extra_sei         <boolean>    E..V....... Pass on extra SEI data (e.g. a53 cc) to be included in the bitstream (default true)
  -udu_sei           <boolean>    E..V....... Pass on user data unregistered SEI if available (default false)
  -intra-refresh     <boolean>    E..V....... Use Periodic Intra Refresh instead of IDR frames (default false)
  -single-slice-intra-refresh <boolean>    E..V....... Use single slice intra refresh (default false)
  -max_slice_size    <int>        E..V....... Maximum encoded slice size in bytes (from 0 to INT_MAX) (default 0)
  -constrained-encoding <boolean>    E..V....... Enable constrainedFrame encoding where each slice in the constrained picture is independent of other slices (default false)
  -tf_level          <int>        E..V....... Specifies the strength of the temporal filtering (from -1 to INT_MAX) (default -1)
     0               0            E..V....... 
     4               4            E..V....... 
  -lookahead_level   <int>        E..V....... Specifies the lookahead level. Higher level may improve quality at the expense of performance. (from -1 to 15) (default -1)
     auto            15           E..V....... 
     0               0            E..V....... 
     1               1            E..V....... 
     2               2            E..V....... 
     3               3            E..V....... 
  -unidir_b          <boolean>    E..V....... Enable use of unidirectional B-Frames. (default false)
  -split_encode_mode <int>        E..V....... Specifies the split encoding mode (from 0 to 15) (default auto)
     disabled        15           E..V....... Disabled for all configurations
     auto            0            E..V....... Enabled or disabled depending on the preset and tuning info
     forced          1            E..V....... Enabled with number of horizontal strips selected by the driver
     2               2            E..V....... Enabled with number of horizontal strips forced to 2 when number of NVENCs > 1
     3               3            E..V....... Enabled with number of horizontal strips forced to 3 when number of NVENCs > 2

```

</details>

#### 倍速
```bash
# 获取时间命令
CURRENT_DURATION=$(ffprobe -v error -show_format -show_streams -i "${INPUT_FILE}" | grep 'duration=' | head -n 1 | cut -d= -f2)
REAL_DURATION=$(echo "scale=6; ${CURRENT_DURATION}/${N}" | bc)
# 变速参数
-filter:v "setpts=PTS/${N}" -t ${REAL_DURATION}
```

#### 慢速
```bash
-filter:v "setpts=PTS*${N}"
```