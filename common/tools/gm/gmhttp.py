import requests
import hashlib
import time
import json

# gmurl = "http://180.150.179.208:6999/"
gmurl = "http://192.168.6.199:8081/"
gmkey = "sssdkdhhfjdgfjjfdggdshd123"

def md5(string):
	return hashlib.md5(string.encode()).hexdigest()

def generate_token(request, timestamp):
	string = timestamp + request + gmkey
	# print(string)
	return md5(string)[:6]

def do_gmcommand(command, params={}):

	request = {"cmd":command}
	request.update(params)
	request = json.dumps(request)

	timestamp = str(int(time.time()))

	headers = {
		"token": generate_token(request, timestamp),
		"timestamp": timestamp,
	}

	# print(headers)
	print(request)
	r = requests.post(gmurl, headers=headers, data=request)
	# print(r.text)
	print(r.content)
	return r.content
# do_gmcommand("table_list", {"type":4})
# do_gmcommand("table_info", {"table_id":100000, "room_id":"roomsvr_1"})
# do_gmcommand("mtt_list")
# do_gmcommand("match_list", {"matchsvr_id":"matchsvr_1", "match_instance_id":"matchsvr_11481460104186490.0"})
# do_gmcommand("match_rank", {"matchsvr_id":"matchsvr_1", "match_instance_id":"matchsvr_11481460104186490.0"})
# # do_gmcommand("online_count")
# do_gmcommand("game_online_count", {"type":8})
# do_gmcommand("marquee", {"content":"[#E8FB2C]这是一个有颜色的跑马灯"})
# do_gmcommand("send_mail", {"rid":1000001,"content":'{"isattach":true,"des":"尊敬的玩家，您报名参加了【星期六资格赛】，但由于一些无法避免的问题，该比赛无法依约举办。您支出的报名费用【100】【筹码】将如数退还。请您在邮件后注意查收。对您造成的不便，恳请您的谅解。","awards":[{"id":1,"num":100}]}'})
# do_gmcommand("push_notice", {"message":"测试推送消息123", "list":[[2, 1000003], [1, 1113556]]})
# do_gmcommand("proplist")
#do_gmcommand("send_chat", {"rid":1000001,"content":"测试聊天消息456"})