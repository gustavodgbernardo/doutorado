from nfstream import NFStreamer

online_streamer = NFStreamer(source="enp9s0", statistical_analysis = True, idle_timeout=60, active_timeout=600)

total_flows_count = online_streamer.to_csv(path="same_attacks.csv", columns_to_anonymize=["src_ip", "dst_ip", "dst_mac","src_mac"], flows_per_file=0, rotate_files=0)
