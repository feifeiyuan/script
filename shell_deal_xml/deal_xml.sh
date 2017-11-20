#!/usr/bin/sh

function attrget() {
	ATTR_PAIR=${1#*$2=\"}  
	echo "${ATTR_PAIR%%\"*}"  
}  
  
function analy_xml () { 
	local IFS=\>  
	while read -d \< ENTITY CDATA  
	do
		local TAG_NAME=${ENTITY%% *}  

		if [[ $TAG_NAME == "id" ]] ; then
			local id_name=`attrget ${ENTITY#* } "name"` 
			echo ""
			echo $id_name
		fi
		if [[ $TAG_NAME == "boost" ]] ; then  
			name=`attrget ${ENTITY#* } "name"`  
			args=`attrget ${ENTITY#* } "args"`
			if [ "$args" != "name=" ] ; then 
				echo $name | busybox awk '{printf("name: %-30s",$1)}'
				echo args: $args
			fi
		fi
	done < $1  
}  

analy_xml deal_xml.xml 




