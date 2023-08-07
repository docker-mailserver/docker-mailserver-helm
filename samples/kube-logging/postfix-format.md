see  https://github.com/winebarrel/fluent-plugin-filter-parse-postfix


## postfix/smtp logs

* sample log accepted
```
Jun 22 04:00:28 smtp-docker-mailserver-7d69ff5b88-qrwqn postfix/smtp[312720]: A18EE1005090: to=<frederic.gourlinxxxxxx.com>, relay=smtp-in-internet-usr-m.xxxx.srv.ttttttt[88.999.77.36]:25, delay=2.3, delays=0.29/0.06/0.74/1.2, dsn=2.0.0, status=sent (250 ok:  Message 256429218 accepted)
```


* sample log bounced
```
Jun 22 08:26:31 smtp-docker-mailserver-7d69ff5b88-qrwqn postfix/smtp[380470]: 4D489100508D: to=<no-reply-unknown@xxx.com>, relay=xxx-com.mail.protection.outlook.com[104.47.2.36]:25, delay=0.38, delays=0.02/0.01/0.22/0.13, dsn=5.4.1, status=bounced (host xxx-com.mail.protection.outlook.com[104.9.8.9] said: 550 5.4.1 Recipient address rejected: Access denied. AS(201806281) [DB5EUR01FT088.eop-EUR01.prod.protection.outlook.com 2023-06-22T08:26:31.592Z 08DB72B25E50380B] (in reply to RCPT TO command))
```



```
{
  "time":"Feb 27 09:02:38",
  "hostname":"MyHOSTNAME",
  "process":"postfix/smtp[26490]",
  "queue_id":"5E31727A35D",
  "to":"*********@myemail.net",
  "domain":"myemail.net",
  "relay":"gateway-f1.isp.att.net[204.127.217.17]:25",
  "conn_use":2,
  "delay":0.58,
  "delays":"0.11/0.03/0.23/0.20",
  "dsn":"2.0.0",
  "status":"sent",
  "status_detail":"(250 ok ; id=en4req0070M63004172202102)"
}
```

list of status: 
status=sent
status=deferred
status=bounced
status=expired



# sample status detail : for sent

(250 2.0.0 from MTA(smtp:[127.0.0.1]:10025): 250 2.0.0 Ok: queued as A18EE1005090)
(250 ok:  Message 256429218 accepted)

# sample status detail : for bounced
(host xxxxx-com.mail.protection.outlook.com[104.x.y.z] said: 550 5.4.1 Recipient address rejected: Access denied. AS(201806281) [DB5EUR01FT088.eop-EUR01.prod.protection.outlook.com 2023-06-22T08:26:31.592Z 08DB72B25E50380B] (in reply to RCPT TO command))




##  logs not well read by Flow

* log with :  to=<support-shuttle@kshuttle.io>, orig_to=<root>

```
Jul  6 07:06:40 smtp-docker-mailserver-74b4c647c4-hgq8z postfix/smtp[164147]: 6AB311E0008B: to=<support-shuttle@kshuttle.io>, orig_to=<root>, relay=mydomain-io.mail.protection.outlook.com[104.47.1.36]:25, delay=1.5, delays=0.02/0.01/0.27/1.2, dsn=2.6.0, status=sent (250 2.6.0 <20230706070639.614B41E0008A@fr1-prod-mailer.mydomain.com> [InternalId=901943135827, Hostname=DB5PR07MB9516.eurprd07.prod.outlook.com] 11251 bytes in 0.064, 171.566 KB/sec Queued mail for delivery
```


### postfix/qmr 

```
$ cat smtp-docker-mailserver-74b4c647c4-hgq8z_dockermailserver.log | grep -v 'User has no mail_replica in userdb' | grep -v  amavis | grep 'from=' | grep -v cleanup | grep -v pickup
Jul  5 20:24:09 smtp-docker-mailserver-74b4c647c4-hgq8z postfix/qmgr[1248]: CA6DC1E0008A: from=<root@fr1-prod-mailer.mydomain.com>, size=815, nrcpt=1 (queue active)
Jul  5 23:00:00 smtp-docker-mailserver-74b4c647c4-hgq8z postfix/qmgr[1248]: 1436A1E0008A: from=<do-not-reply@kmydomain.io>, size=973, nrcpt=1 (queue active)
Jul  5 23:00:11 smtp-docker-mailserver-74b4c647c4-hgq8z postfix/qmgr[1248]: 4C7B91E0008B: from=<do-not-reply@kmydomain.io>, size=1751, nrcpt=1 (queue active)
Jul  5 23:15:00 smtp-docker-mailserver-74b4c647c4-hgq8z postfix/qmgr[1248]: 12C581E0008A: from=<do-not-reply@kmydomain.io>, size=977, nrcpt=1 (queue active)
Jul  5 23:15:09 smtp-docker-mailserver-74b4c647c4-hgq8z postfix/qmgr[1248]: B1D631E0008B: from=<do-not-reply@kmydomain.io>, size=1755, nrcpt=1 (queue active)
Jul  5 23:30:00 smtp-docker-mailserver-74b4c647c4-hgq8z postfix/qmgr[1248]: 112FF1E0008A: from=<do-not-reply@kmydomain.io>, size=972, nrcpt=1 (queue active)
Jul  5 23:30:09 smtp-docker-mailserver-74b4c647c4-hgq8z postfix/qmgr[1248]: A91F31E0008B: from=<do-not-reply@kmydomain.io>, size=1750, nrcpt=1 (queue active)
Jul  5 23:40:00 smtp-docker-mailserver-74b4c647c4-hgq8z postfix/qmgr[1248]: 12BD01E0008A: from=<do-not-reply@kmydomain.io>, size=975, nrcpt=1 (queue active)
Jul  5 23:40:09 smtp-docker-mailserver-74b4c647c4-hgq8z postfix/qmgr[1248]: 789FA1E0008B: from=<do-not-reply@kmydomain.io>, size=1753, nrcpt=1 (queue active)
Jul  5 23:50:00 smtp-docker-mailserver-74b4c647c4-hgq8z postfix/qmgr[1248]: 15D3B1E0008A: from=<do-not-reply@kmydomain.io>, size=977, nrcpt=1 (queue active)
Jul  5 23:50:09 smtp-docker-mailserver-74b4c647c4-hgq8z postfix/qmgr[1248]: 6DFD41E0008B: from=<do-not-reply@kmydomain.io>, size=1755, nrcpt=1 (queue active)
Jul  6 00:08:58 smtp-docker-mailserver-74b4c647c4-hgq8z postfix/qmgr[1248]: B67C81E0008A: from=<do-not-reply@kmydomain.io>, size=40009, nrcpt=2 (queue active)
Jul  6 00:08:59 smtp-docker-mailserver-74b4c647c4-hgq8z postfix/qmgr[1248]: EA8791E0008B: from=<do-not-reply@kmydomain.io>, size=6549, nrcpt=7 (queue active)
Jul  6 00:09:09 smtp-docker-mailserver-74b4c647c4-hgq8z postfix/qmgr[1248]: 49D8F1E0008C: from=<do-not-reply@kmydomain.io>, size=7295, nrcpt=7 (queue active)
Jul  6 00:09:09 smtp-docker-mailserver-74b4c647c4-hgq8z postfix/qmgr[1248]: DA89F1E0008B: from=<do-not-reply@kmydomain.io>, size=40757, nrcpt=2 (queue active)
Jul  6 04:00:15 smtp-docker-mailserver-74b4c647c4-hgq8z postfix/qmgr[1248]: B91601E0008A: from=<do-not-reply@kmydomain.io>, size=95822, nrcpt=2 (queue active)
Jul  6 04:00:16 smtp-docker-mailserver-74b4c647c4-hgq8z postfix/qmgr[1248]: E4FFC1E0008B: from=<do-not-reply@kmydomain.io>, size=2414, nrcpt=7 (queue active)
Jul  6 04:00:25 smtp-docker-mailserver-74b4c647c4-hgq8z postfix/qmgr[1248]: C6E161E0008C: from=<do-not-reply@kmydomain.io>, size=96570, nrcpt=2 (queue active)
Jul  6 04:00:26 smtp-docker-mailserver-74b4c647c4-hgq8z postfix/qmgr[1248]: A46281E0008A: from=<do-not-reply@kmydomain.io>, size=3160, nrcpt=7 (queue active)
Jul  6 04:32:32 smtp-docker-mailserver-74b4c647c4-hgq8z postfix/qmgr[1248]: E72D71E0008A: from=<kskipper@kmydomain.io>, size=13053, nrcpt=2 (queue active)
Jul  6 04:32:41 smtp-docker-mailserver-74b4c647c4-hgq8z postfix/qmgr[1248]: 342641E0008B: from=<kskipper@kmydomain.io>, size=13804, nrcpt=2 (queue active)
Jul  6 04:33:58 smtp-docker-mailserver-74b4c647c4-hgq8z postfix/qmgr[1248]: 2267A1E0008A: from=<kskipper@kmydomain.io>, size=13555, nrcpt=1 (queue active)
Jul  6 04:33:58 smtp-docker-mailserver-74b4c647c4-hgq8z postfix/qmgr[1248]: 591641E0008B: from=<kskipper@kmydomain.io>, size=20614, nrcpt=1 (queue active)
Jul  6 04:33:58 smtp-docker-mailserver-74b4c647c4-hgq8z postfix/qmgr[1248]: 6F7291E0008C: from=<kskipper@kmydomain.io>, size=15153, nrcpt=1 (queue active)
Jul  6 04:33:58 smtp-docker-mailserver-74b4c647c4-hgq8z postfix/qmgr[1248]: 845CC1E0008D: from=<kskipper@kmydomain.io>, size=18974, nrcpt=1 (queue active)
Jul  6 04:33:58 smtp-docker-mailserver-74b4c647c4-hgq8z postfix/qmgr[1248]: 9CD461E0008E: from=<kskipper@kmydomain.io>, size=16950, nrcpt=1 (queue active)
Jul  6 04:33:58 smtp-docker-mailserver-74b4c647c4-hgq8z postfix/qmgr[1248]: B068E1E0008F: from=<kskipper@kmydomain.io>, size=15169, nrcpt=1 (queue active)
Jul  6 04:34:07 smtp-docker-mailserver-74b4c647c4-hgq8z postfix/qmgr[1248]: 572781E00090: from=<kskipper@kmydomain.io>, size=14337, nrcpt=1 (queue active)
Jul  6 04:34:08 smtp-docker-mailserver-74b4c647c4-hgq8z postfix/qmgr[1248]: 6B93A1E0008A: from=<kskipper@kmydomain.io>, size=21396, nrcpt=1 (queue active)
Jul  6 04:34:16 smtp-docker-mailserver-74b4c647c4-hgq8z postfix/qmgr[1248]: AF1671E0008A: from=<kskipper@kmydomain.io>, size=15935, nrcpt=1 (queue active)
Jul  6 04:34:17 smtp-docker-mailserver-74b4c647c4-hgq8z postfix/qmgr[1248]: DA1BA1E0008B: from=<kskipper@kmydomain.io>, size=19765, nrcpt=1 (queue active)
Jul  6 04:34:25 smtp-docker-mailserver-74b4c647c4-hgq8z postfix/qmgr[1248]: E8E051E0008A: from=<kskipper@kmydomain.io>, size=17728, nrcpt=1 (queue active)
Jul  6 04:34:27 smtp-docker-mailserver-74b4c647c4-hgq8z postfix/qmgr[1248]: 16C051E0008A: from=<kskipper@kmydomain.io>, size=15951, nrcpt=1 (queue active)
Jul  6 04:34:41 smtp-docker-mailserver-74b4c647c4-hgq8z postfix/qmgr[1248]: 287C01E0008B: from=<kskipper@kmydomain.io>, size=12853, nrcpt=1 (queue active)
Jul  6 04:34:50 smtp-docker-mailserver-74b4c647c4-hgq8z postfix/qmgr[1248]: 5B1601E0008A: from=<kskipper@kmydomain.io>, size=13635, nrcpt=1 (queue active)
Jul  6 07:06:39 smtp-docker-mailserver-74b4c647c4-hgq8z postfix/qmgr[1248]: 614B41E0008A: from=<root@fr1-prod-mailer.mydomain.com>, size=2413, nrcpt=1 (queue active)
Jul  6 07:06:39 smtp-docker-mailserver-74b4c647c4-hgq8z postfix/qmgr[1248]: 6AB311E0008B: from=<root@fr1-prod-mailer.mydomain.com>, size=2582, nrcpt=1 (queue active)
```