#!/bin/sh

#set -ex

function cut_video() {
  # Get arguments
  local filename=$1
  local start_time=$2
  local end_time=$3
  local output_file=$4
  local resolution=$5
  local bitrate=$6  

  # Use ffmpeg to cut video
  ffmpeg -nostdin -i $filename -ss $start_time -to $end_time -vf "scale=${resolution}" -b:v ${bitrate} -c:v hevc_videotoolbox -q:v 85 -video_track_timescale 90000 $output_file
}

function cut_and_rotate_video_anticlockwise() {
  # Get arguments
  local filename=$1
  local start_time=$2
  local end_time=$3
  local output_file=$4
  local resolution=$5
  local bitrate=$6

  # Use ffmpeg to cut and rotate video
  ffmpeg -nostdin -i $filename -ss $start_time -to $end_time -vf "transpose=1,scale=${resolution}" -b:v ${bitrate} -c:v hevc_videotoolbox -q:v 85 -video_track_timescale 90000 $output_file
}

function cut_and_rotate_video_clockwise() {
  # Get arguments
  local filename=$1
  local start_time=$2
  local end_time=$3
  local output_file=$4
  local resolution=$5
  local bitrate=$6  

  # Use ffmpeg to cut and rotate video
  ffmpeg -nostdin -i $filename -ss $start_time -to $end_time -vf "transpose=2,scale=${resolution}" -b:v ${bitrate} -c:v hevc_videotoolbox -q:v 85 -video_track_timescale 90000 $output_file
}

function ffmpeg_join_files() {
    local output_file=$1
    local input_files=("${@:2}")

	if [ ${#input_files[@]} -le 1 ]; then
    	return 0
	fi

    local input_args=""
    for input_file in "${input_files[@]}"; do
        input_args+=" -i ${input_file}"
    done
    ffmpeg ${input_args} -filter_complex "concat=n=${#input_files[@]}:v=1:a=1" -c:v hevc_videotoolbox -q:v 85  -y "${output_file}.mp4"
}

function get_duration() {
  local filename=$1
  local duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$filename")
  local floored_duration=$(echo "$duration/1" | bc)
  printf "%.0f" $floored_duration
}

function duration_diff_in_seconds() {
    local duration1=$1
    local duration2=$2
    local duration1_seconds=$(date -j -f "%H:%M:%S" "${duration1}" "+%s")
    local duration2_seconds=$(date -j -f "%H:%M:%S" "${duration2}" "+%s")
    local diff_seconds=$((duration2_seconds - duration1_seconds))
    echo "${diff_seconds}"
}

function find_suitable_resolution(){
	config=$1
	
	min_resx=10000000
	min_resy=10000000

	while IFS== read -r line; do
		
		input_file=$( echo "$line" | awk -F' ' '{print $1}')

		resx=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0:s=x ${input_file} )
        resy=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0:s=x ${input_file} )

        if [ ${resx} -lt ${min_resx} ]; then
        	min_resx=${resx}
        fi

        if [ ${resy} -lt ${min_resy} ]; then
        	min_resy=${resy}
        fi
	done < "$config"

    echo "${min_resx}:${min_resy}"
}

function find_suitable_bitrate(){
	config=$1
	min_bitrate=100000000

	while IFS== read -r line; do
		
		input_file=$( echo "$line" | awk -F' ' '{print $1}')

		bitrate=$(ffprobe -v error -select_streams v:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 ${input_file} )

        if [ ${bitrate} -lt ${min_bitrate} ]; then
        	min_bitrate=${bitrate}
        fi
	done < "$config"

    echo "${min_bitrate}"
}

function create_cuts(){

	local config=$1
	local output_file=$2

	local resolution=$(find_suitable_resolution $config)
	local bitrate=$(find_suitable_bitrate $config)
	
	local iterator=1;
	while IFS== read -r line; do
		
		input_file=$( echo "$line" | awk -F' ' '{print $1}')
		start=$( echo "$line" | awk -F' ' '{print $2}')
		end=$( echo "$line" | awk -F' ' '{print $3}')
		cut_arg=$( echo "$line" | awk -F' ' '{print $5}')
		output_part_file="${output_file}_cut_${iterator}.mp4"

		if [ -n "$cut_arg" ] && [ "$cut_arg" = "r_flip" ]; then
			cut_and_rotate_video_clockwise "$input_file" "$start" "$end" "$output_part_file" "$resolution" "$bitrate"
		elif [ -n "$cut_arg" ] && [ "$cut_arg" = "l_flip" ]; then
			cut_and_rotate_video_anticlockwise "$input_file" "$start" "$end" "$output_part_file" "$resolution" "$bitrate"
		else
			cut_video "$input_file" "$start" "$end" "$output_part_file" "$resolution" "$bitrate"
		fi
		iterator=$((iterator + 1));
	done < "$config"
}

# video1 00:00:00 00:03:00 
# video2 00:04:00 00:06:00 
# video3 00:00:00 00:03:00 no_fade 	-> fade_seg_1 len3
# video2 00:06:00 00:08:00  		
# video4 00:06:00 00:10:00 no_fade  -> fade_seg_2 len2
# video3 00:06:00 00:08:00 
# video3 00:02:00 00:08:00 
# video3 00:02:00 00:08:00 no_fade  -> fade_seg_3 len 3
# video3 00:02:00 00:08:00 no_fade  -> fade_seg_4 len 1
# video3 00:02:00 00:08:00 no_fade	-> fade_seg_5 len 1
# video3 00:02:00 00:08:00 
# video3 00:02:00 00:08:00 -> fade_seg_6 len 1

# no_fade means join the end of this segment without fade with next segment

function generate_video_filter_string() {
  local output_file=$1
  local input_files=("${@:2}")
  local vfilters=""
  local afilters=""

  local duration=$(get_duration ${input_files[0]} )
  local offset=$(( $duration + $offset - 1 ))
  local command="ffmpeg -nostdin -i ${input_files[0]} "

  for ((i=1; i<${#input_files[@]}; i++))
  do

    if [ $i -gt 1 ]; then
      vfilters+=[vfade$((i-1))]
      afilters+=[afade$((i-1))]
    else
      vfilters+="[$((i-1))]"
      afilters+="[$((i-1))]"
    fi
    
    vfilters+="[${i}:v]xfade=transition=fade:duration=1:offset=${offset}"
    afilters+="[${i}:a]acrossfade=d=1"

    if [ $i -eq $(( ${#input_files[@]} - 1)) ]; then
      vfilters+=",format=yuv420p;"
    else
      vfilters+="[vfade${i}]; "
      afilters+="[afade${i}]; "
    fi

    command+="-i ${input_files[${i}]} "
    duration=$(get_duration ${input_files["$i"]} )
    offset=$(( $duration + $offset - 1 ))

  done

  command+="-filter_complex \"${vfilters}${afilters}\" -c:v hevc_videotoolbox -q:v 85 -movflags +faststart ${output_file}"
  echo "$command"
}

# input 
# output file name , array of files
function crossfade_videos() {

  local output_file="$1"
  local input_files=("${@:2}")

  	if [ ${#input_files[@]} -eq 0 ]; then
    	return 0
	fi

	if [ ${#input_files[@]} -eq 1 ]; then
    	mv ${input_files[0]} "$output_file"
    	return 0
	fi

	command=$( generate_video_filter_string "$output_file" "${input_files[@]}" )
	echo $command

	eval $command

}

function join_cuts(){
	local config=$1
	local output_file=$2

	# array that joins cross faded videos normally
	# will remain empty if not required
	local final_cuts=()
	local cuts=()
	
	final_cut_iterator=1;
	iterator=1;
	while IFS== read -r line; do
		output_part_file="${output_file}_join_${iterator}.mp4"

		input_file=${output_file}"_cut_"${iterator}".mp4"

		join_arg=$( echo "$line" | awk -F' ' '{print $4}')

		cuts+=("$input_file")

		if [ -n "$join_arg"  ] && [ "$join_arg" = "no_fade" ] ; then
				
			final_cut_iterator=$((final_cut_iterator + 1));	
			
			crossfade_videos "$output_part_file" "${cuts[@]}"
			cuts=()
			final_cuts+=("$output_part_file")

		fi
		iterator=$((iterator + 1));
	done < "$config"

	if [ ${#cuts[@]} -gt 0 ]; then
		crossfade_videos "$output_part_file" "${cuts[@]}"
		final_cuts+=("$output_part_file")
	fi


	ffmpeg_join_files "$output_file" "${final_cuts[@]}"

}


config=$1
output_file=$2

create_cuts "$config" "$output_file"
join_cuts "$config" "$output_file"
