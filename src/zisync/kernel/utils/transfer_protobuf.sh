#!/bin/bash
#########################################################################
# Author: Wang Wencan
# Created Time: Tue 07 Jan 2014 07:23:36 PM CST
# File Name: tranfer_protobuf.sh
# Description: 
#########################################################################
SRC=$1
REQ_DST=$2
REP_DST=$3

_insert() {
    insert_words=$1
    sed -i "${insert_line}a\\$insert_words\\" $DST
    insert_line=$(($insert_line + 1))
}


start_str="\\/\\* Generated by shell script \\*\\/"
end_str="\\/\\* End of Generated by shell script \\*\\/"
codes=$(sed -n "/enum MsgCode/,/}/p" $SRC | grep "=" | \
    cut -d/ -f 1 | cut -d= -f 1)

# generate request
DST=$REQ_DST
insert_line=$(($(sed -n "/$end_str/=" $DST) - 1))
#sed -i "$(($insert_line+1)), /${end_str}/D" $DST
#_insert ""
for code in $codes; do
    code=$(echo $code)
    msg=$(echo $code | sed 's/MC_//g' | sed 's/.*/\L&/g' | \
        sed 's/_[a-z]\|\b[a-z]/\U&/g' | sed 's/_//g')
    request=$(echo $msg | grep -i request)
    if [ -z "$request" ]; then
        continue
    fi
    response=$(echo $request | sed s/Request/Response/g)
    exist=$(grep "class $request" $DST)
    if [ -n "$exist" ]; then
        continue
    fi
    has_body=$(grep "message Msg$request" $SRC)
    _insert "class $request : public Request {"
    _insert " public:"
    _insert "  $request() {}"
    _insert "  virtual ~$request() {}"
    if [ -n "$has_body" ]; then # has body
        _insert "  virtual ::google::protobuf::Message* mutable_msg() { return &request_msg_; }" 
        _insert "  Msg$request* mutable_request() { return &request_msg_; }"
        _insert "  const Msg$request& request() const { return request_msg_; }"
    else
        _insert "  virtual ::google::protobuf::Message* mutable_msg() { return NULL; }"
    fi
    _insert "  virtual MsgCode msg_code() const { return $code; }"
    _insert " private:"
    _insert "  $request($request&);"
    _insert "  void operator=($request&);"
    if [ -n "$has_body" ]; then # has body
        _insert ""
        _insert "  Msg$request  request_msg_;"
    fi
    _insert "};"
    _insert ""
done
touch $DST

# insert request
DST=$REP_DST
insert_line=$(($(sed -n "/$end_str/=" $DST) - 1))
for code in $codes; do
    code=$(echo $code)
    msg=$(echo $code | sed 's/MC_//g' | sed 's/.*/\L&/g' | \
        sed 's/_[a-z]\|\b[a-z]/\U&/g' | sed 's/_//g')
    response=$(echo $msg | grep -i response)
    if [ -z "$response" ]; then
        continue
    fi
    exist=$(grep "class $response" $DST)
    if [ -n "$exist" ]; then
        continue
    fi
    has_body=$(grep "message Msg$response" $SRC)
    _insert "class $response : public Response {"
    _insert " public:"
    _insert "  $response() {}"
    _insert "  virtual ~$response() {}"
    if [ -n "$has_body" ]; then # has body
        _insert "  virtual ::google::protobuf::Message* mutable_msg() { return &response_msg_; }"
        _insert "  Msg$response* mutable_response() { return &response_msg_; }"
        _insert "  const Msg$response& response() const { return response_msg_; }"
    else
        _insert "  virtual ::google::protobuf::Message* mutable_msg() { return NULL; }"
    fi
    _insert "  virtual MsgCode msg_code() const { return $code; }"
    _insert " private:"
    _insert "  $response($response&);"
    _insert " void operator=($response&);"
    if [ -n "$has_body" ]; then # has body
        _insert ""
        _insert "  Msg$response  response_msg_;"
    fi
    _insert "};"
    _insert ""
done
touch $DST

