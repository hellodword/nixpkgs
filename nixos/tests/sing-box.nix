import ./make-test-python.nix (
  { lib, ... }:
  let
    server_name = "acme.test";
    hosts = ''
      216.58.211.1 ${server_name}
      216.58.211.1 target.lan
      216.58.211.2 server.lan
      216.58.211.3 normal.lan
      216.58.211.4 tun.lan
    '';
    singTlsClient = {
      enabled = true;
      server_name = server_name;
      certificate_path = ./common/acme/server/acme.test.cert.pem;
    };
    singTlsServer = singTlsClient // {
      key_path = ./common/acme/server/acme.test.key.pem;
    };
    generateCommon = index: {
      networking = {
        firewall.enable = false;
        extraHosts = hosts;
        useDHCP = false;
        interfaces.eth1 = {
          ipv4.addresses = [
            {
              address = "192.168.0.${toString index}";
              prefixLength = 24;
            }
            {
              address = "216.58.211.${toString index}";
              prefixLength = 24;
            }
          ];
        };
      };

      security.pki.certificates = [
        (builtins.readFile ./common/acme/server/ca.cert.pem)
      ];
    };
  in
  {

    name = "sing-box";

    meta = {
      maintainers = with lib.maintainers; [ nickcao ];
    };

    nodes = {
      target =
        { pkgs, ... }:
        (generateCommon 1)
        // {
          services.dnsmasq.enable = true;

          services.nginx = {
            enable = true;
            package = pkgs.nginxQuic;

            virtualHosts."${server_name}" = {
              onlySSL = true;
              sslCertificate = ./common/acme/server/acme.test.cert.pem;
              sslCertificateKey = ./common/acme/server/acme.test.key.pem;
              http2 = true;
              http3 = true;
              http3_hq = false;
              quic = true;
              reuseport = true;
              root = lib.mkForce (
                pkgs.runCommandLocal "testdir" { } ''
                  mkdir "$out"
                  cat > "$out/index.html" <<EOF
                  <html><body>Hello World!</body></html>
                  EOF
                  cat > "$out/example.txt" <<EOF
                  Check http3 protocol.
                  EOF
                ''
              );
            };
          };
        };

      server =
        { pkgs, ... }:
        (generateCommon 2)
        // {
          services.sing-box = {
            enable = true;
            settings = {
              inbounds = [
                {
                  type = "mixed";
                  tag = "inbound:mixed";
                  listen = "0.0.0.0";
                  listen_port = 1080;
                  users = [
                    {
                      username = "user";
                      password = {
                        _secret = pkgs.writeText "password" "supersecret";
                      };
                    }
                  ];
                }
                {
                  type = "direct";
                  tag = "inbound:direct:tcp";
                  listen = "0.0.0.0";
                  listen_port = 1081;
                  network = "tcp";
                  override_address = "target.lan";
                  override_port = 443;
                }
                {
                  type = "direct";
                  tag = "inbound:direct:udp";
                  listen = "0.0.0.0";
                  listen_port = 1081;
                  network = "udp";
                  override_address = "target.lan";
                  override_port = 443;
                }
                {
                  type = "shadowsocks";
                  tag = "inbound:shadowsocks";
                  listen = "0.0.0.0";
                  listen_port = 1082;
                  method = "2022-blake3-aes-128-gcm";
                  password = "8JCsPssfgS8tiRwiMlhARg==";
                }
                {
                  type = "vmess";
                  tag = "inbound:vmess";
                  listen = "0.0.0.0";
                  listen_port = 1083;
                  users = [
                    {
                      name = "sekai";
                      uuid = "bf000d23-0752-40b4-affe-68f7707a9661";
                      alterId = 0;
                    }
                  ];
                  tls = singTlsServer;
                }
                {
                  type = "trojan";
                  tag = "inbound:trojan";
                  listen = "0.0.0.0";
                  listen_port = 1084;
                  users = [
                    {
                      name = "sekai";
                      password = "8JCsPssfgS8tiRwiMlhARg==";
                    }
                  ];
                  tls = singTlsServer;
                }
                {
                  type = "hysteria";
                  tag = "inbound:hysteria";
                  listen = "0.0.0.0";
                  listen_port = 1085;
                  up_mbps = 100;
                  down_mbps = 100;
                  obfs = "fuck me till the daylight";
                  users = [
                    {
                      name = "sekai";
                      auth_str = "password";
                    }
                  ];
                  tls = singTlsServer;
                }
                {
                  type = "hysteria2";
                  tag = "inbound:hysteria2";
                  listen = "0.0.0.0";
                  listen_port = 1086;
                  up_mbps = 100;
                  down_mbps = 100;
                  obfs = {
                    type = "salamander";
                    password = "cry_me_a_r1ver";
                  };
                  users = [
                    {
                      name = "tobyxdd";
                      password = "goofy_ahh_password";
                    }
                  ];
                  tls = singTlsServer;
                }
                {
                  type = "tuic";
                  tag = "inbound:tuic";
                  listen = "0.0.0.0";
                  listen_port = 1087;
                  users = [
                    {
                      name = "sekai";
                      uuid = "059032A9-7D40-4A96-9BB1-36823D848068";
                      password = "hello";
                    }
                  ];
                  congestion_control = "cubic";
                  auth_timeout = "3s";
                  zero_rtt_handshake = false;
                  heartbeat = "10s";
                  tls = singTlsServer;
                }
                {
                  type = "vless";
                  tag = "inbound:vless";
                  listen = "0.0.0.0";
                  listen_port = 1088;
                  users = [
                    {
                      name = "sekai";
                      uuid = "bf000d23-0752-40b4-affe-68f7707a9661";
                      flow = "xtls-rprx-vision";
                    }
                  ];
                  tls = singTlsServer;
                }
                {
                  type = "vmess";
                  tag = "inbound:vmess-ws";
                  listen = "0.0.0.0";
                  listen_port = 1089;
                  users = [
                    {
                      name = "sekai";
                      uuid = "bf000d23-0752-40b4-affe-68f7707a9661";
                      alterId = 0;
                    }
                  ];
                  transport = {
                    type = "ws";
                    path = "/path";
                  };
                  tls = singTlsServer;
                }
              ];
              outbounds = [
                {
                  type = "direct";
                  tag = "outbound:direct";
                }
              ];
              route = {
                final = "outbound:direct";
              };
            };
          };
        };

      normalClient =
        { pkgs, ... }:
        (generateCommon 3)
        // {
          environment.systemPackages = [
            pkgs.curlHTTP3
            pkgs.dnsutils
          ];

          services.sing-box = {
            enable = true;
            settings = {
              experimental = {
                clash_api = {
                  external_controller = "127.0.0.1:9090";
                };
              };
              dns = {
                final = "dns:default";
                servers = [
                  {
                    tag = "dns:default";
                    address = "216.58.211.1";
                    detour = "outbound:direct";
                  }
                ];
              };
              inbounds = [
                {
                  type = "mixed";
                  tag = "inbound:mixed:socks";
                  listen = "127.0.0.1";
                  listen_port = 1080;
                }
                {
                  type = "mixed";
                  tag = "inbound:mixed:shadowsocks";
                  listen = "127.0.0.1";
                  listen_port = 1082;
                }
                {
                  type = "mixed";
                  tag = "inbound:mixed:vmess";
                  listen = "127.0.0.1";
                  listen_port = 1083;
                }
                {
                  type = "mixed";
                  tag = "inbound:mixed:trojan";
                  listen = "127.0.0.1";
                  listen_port = 1084;
                }
                {
                  type = "mixed";
                  tag = "inbound:mixed:hysteria";
                  listen = "127.0.0.1";
                  listen_port = 1085;
                }
                {
                  type = "mixed";
                  tag = "inbound:mixed:hysteria2";
                  listen = "127.0.0.1";
                  listen_port = 1086;
                }
                {
                  type = "mixed";
                  tag = "inbound:mixed:tuic";
                  listen = "127.0.0.1";
                  listen_port = 1087;
                }
                {
                  type = "mixed";
                  tag = "inbound:mixed:vless";
                  listen = "127.0.0.1";
                  listen_port = 1088;
                }
                {
                  type = "mixed";
                  tag = "inbound:mixed:vmess-ws";
                  listen = "127.0.0.1";
                  listen_port = 1089;
                }
                {
                  type = "direct";
                  tag = "inbound:dns";
                  listen = "127.0.0.1";
                  listen_port = 1090;
                }
              ];
              outbounds = [
                {
                  type = "block";
                  tag = "outbound:block";
                }
                {
                  type = "direct";
                  tag = "outbound:direct";
                }
                {
                  tag = "outbound:dns";
                  type = "dns";
                }
                {
                  type = "socks";
                  tag = "outbound:socks";
                  server = "server.lan";
                  server_port = 1080;
                  version = "5";
                  username = "user";
                  password = "supersecret";
                }
                {
                  type = "shadowsocks";
                  tag = "outbound:shadowsocks";
                  server = "server.lan";
                  server_port = 1082;
                  method = "2022-blake3-aes-128-gcm";
                  password = "8JCsPssfgS8tiRwiMlhARg==";
                }
                {
                  type = "vmess";
                  tag = "outbound:vmess";
                  server = "server.lan";
                  server_port = 1083;
                  uuid = "bf000d23-0752-40b4-affe-68f7707a9661";
                  security = "auto";
                  alter_id = 0;
                  tls = singTlsClient;
                }
                {
                  type = "trojan";
                  tag = "outbound:trojan";
                  server = "server.lan";
                  server_port = 1084;
                  password = "8JCsPssfgS8tiRwiMlhARg==";
                  tls = singTlsClient;
                }
                {
                  type = "hysteria";
                  tag = "outbound:hysteria";
                  server = "server.lan";
                  server_port = 1085;
                  up_mbps = 100;
                  down_mbps = 100;
                  obfs = "fuck me till the daylight";
                  auth_str = "password";
                  tls = singTlsClient;
                }
                {
                  type = "hysteria2";
                  tag = "outbound:hysteria2";
                  server = "server.lan";
                  server_port = 1086;
                  up_mbps = 100;
                  down_mbps = 100;
                  obfs = {
                    type = "salamander";
                    password = "cry_me_a_r1ver";
                  };
                  password = "goofy_ahh_password";
                  tls = singTlsClient;
                }
                {
                  type = "tuic";
                  tag = "outbound:tuic";
                  server = "server.lan";
                  server_port = 1087;
                  uuid = "059032A9-7D40-4A96-9BB1-36823D848068";
                  password = "hello";
                  congestion_control = "cubic";
                  zero_rtt_handshake = false;
                  heartbeat = "10s";
                  tls = singTlsClient;
                }
                {
                  type = "vless";
                  tag = "outbound:vless";
                  server = "server.lan";
                  server_port = 1088;
                  uuid = "bf000d23-0752-40b4-affe-68f7707a9661";
                  flow = "xtls-rprx-vision";
                  tls = singTlsClient;
                }
                {
                  type = "vmess";
                  tag = "outbound:vmess-ws";
                  server = "server.lan";
                  server_port = 1089;
                  uuid = "bf000d23-0752-40b4-affe-68f7707a9661";
                  security = "auto";
                  alter_id = 0;
                  transport = {
                    type = "ws";
                    headers = {
                      Host = server_name;
                    };
                    path = "/path";
                  };
                  tls = singTlsClient;
                }
              ];
              route = {
                final = "outbound:block";
                rules = [
                  {
                    inbound = [
                      "inbound:dns"
                    ];
                    outbound = "outbound:dns";
                  }
                  {
                    inbound = [
                      "inbound:mixed:socks"
                    ];
                    outbound = "outbound:socks";
                  }
                  {
                    inbound = [
                      "inbound:mixed:shadowsocks"
                    ];
                    outbound = "outbound:shadowsocks";
                  }
                  {
                    inbound = [
                      "inbound:mixed:vmess"
                    ];
                    outbound = "outbound:vmess";
                  }
                  {
                    inbound = [
                      "inbound:mixed:trojan"
                    ];
                    outbound = "outbound:trojan";
                  }
                  {
                    inbound = [
                      "inbound:mixed:hysteria"
                    ];
                    outbound = "outbound:hysteria";
                  }
                  {
                    inbound = [
                      "inbound:mixed:hysteria2"
                    ];
                    outbound = "outbound:hysteria2";
                  }
                  {
                    inbound = [
                      "inbound:mixed:tuic"
                    ];
                    outbound = "outbound:tuic";
                  }
                  {
                    inbound = [
                      "inbound:mixed:vless"
                    ];
                    outbound = "outbound:vless";
                  }
                  {
                    inbound = [
                      "inbound:mixed:vmess-ws"
                    ];
                    outbound = "outbound:vmess-ws";
                  }
                ];
              };
            };
          };
        };

      tunClient =
        { pkgs, ... }:
        (generateCommon 4)
        // {

          environment.systemPackages = [ pkgs.curlHTTP3 ];

          services.sing-box = {
            enable = true;
            settings = {
              log = {
                disabled = false;
                level = "info";
                timestamp = true;
                output = "/tmp/sing-box.log";
              };
              inbounds = [
                {
                  type = "tun";
                  tag = "inbound:tun";
                  interface_name = "tun0";
                  inet4_address = "172.19.0.1/30";
                  inet6_address = "fdfe:dcba:9876::1/126";
                  auto_route = true;
                  strict_route = false;
                  sniff = true;
                }
              ];
              outbounds = [
                {
                  type = "block";
                  tag = "outbound:block";
                }
                {
                  type = "socks";
                  tag = "outbound:socks";
                  server = "server.lan";
                  server_port = 1080;
                  version = "5";
                  username = "user";
                  password = "supersecret";
                }
              ];
              route = {
                final = "outbound:block";
                rules = [
                  {
                    inbound = [
                      "inbound:tun"
                    ];
                    outbound = "outbound:socks";
                  }
                ];
              };
            };
          };
        };
    };

    testScript = ''
      start_all()

      target.systemctl("start network-online.target")
      target.wait_for_unit("network-online.target")
      target.wait_for_unit("nginx.service")
      target.wait_for_open_port(443)
      target.wait_for_unit("dnsmasq.service")
      target.wait_for_open_port(53)

      server.systemctl("start network-online.target")
      server.wait_for_unit("network-online.target")
      server.wait_for_unit("sing-box.service")
      server.wait_for_open_port(1080)
      server.wait_for_open_port(1081)
      server.wait_for_open_port(1082)
      server.wait_for_open_port(1083)
      server.wait_for_open_port(1084)
      server.wait_for_open_port(1088)
      server.wait_for_open_port(1089)

      normalClient.systemctl("start network-online.target")
      normalClient.wait_for_unit("network-online.target")
      normalClient.wait_for_unit("sing-box.service")
      normalClient.wait_for_open_port(9090)
      normalClient.wait_for_open_port(1080)
      normalClient.wait_for_open_port(1082)
      normalClient.wait_for_open_port(1083)
      normalClient.wait_for_open_port(1084)
      normalClient.wait_for_open_port(1085)
      normalClient.wait_for_open_port(1086)
      normalClient.wait_for_open_port(1087)
      normalClient.wait_for_open_port(1088)
      normalClient.wait_for_open_port(1089)
      normalClient.wait_for_open_port(1090)

      # inbound:mixed
      normalClient.succeed("curl --fail --max-time 10 --proxy http://user:supersecret@server.lan:1080 https://${server_name}")
      normalClient.fail("curl --fail --max-time 10 --proxy http://user:supervillain@server.lan:1080 https://${server_name}")
      normalClient.succeed("curl --fail --max-time 10 --proxy socks5://user:supersecret@server.lan:1080 https://${server_name}")

      # inbound:direct:tcp
      normalClient.succeed("curl --fail --max-time 10 --resolve '${server_name}:1081:216.58.211.2' https://${server_name}:1081")
      # inbound:direct:udp
      normalClient.succeed("curl --fail --max-time 10 --verbose --http3-only --head --resolve '${server_name}:1081:216.58.211.2' https://${server_name}:1081 | grep 'HTTP/3 200'")

      # outbound:socks
      normalClient.succeed("curl --fail --max-time 10 --proxy socks5://localhost:1080 https://${server_name}")

      tunClient.systemctl("start network-online.target")
      tunClient.wait_for_unit("network-online.target")
      tunClient.wait_for_unit("sing-box.service")

      # tcp of inbound:tun
      tunClient.succeed("curl --fail --max-time 10 --interface tun0 --http2 https://${server_name}")
      # udp of inbound:tun
      tunClient.succeed("curl --fail --max-time 10 --interface tun0 --http3-only --head https://${server_name} | grep 'HTTP/3 200'")

      # shadowsocks
      normalClient.succeed("curl --fail --max-time 10 --proxy socks5://localhost:1082 https://${server_name}")

      # vmess tls
      normalClient.succeed("curl --fail --max-time 10 --proxy socks5://localhost:1083 https://${server_name}")

      # trojan tls
      normalClient.succeed("curl --fail --max-time 10 --proxy socks5://localhost:1084 https://${server_name}")

      # hysteria tls
      normalClient.succeed("curl --fail --max-time 10 --proxy socks5://localhost:1085 https://${server_name}")

      # hysteria2 tls
      normalClient.succeed("curl --fail --max-time 10 --proxy socks5://localhost:1086 https://${server_name}")

      # tuic
      normalClient.succeed("curl --fail --max-time 10 --proxy socks5://localhost:1087 https://${server_name}")

      # vless tls
      normalClient.succeed("curl --fail --max-time 10 --proxy socks5://localhost:1088 https://${server_name}")

      # vmess ws tls
      normalClient.succeed("curl --fail --max-time 10 --proxy socks5://localhost:1089 https://${server_name}")

      # dns
      normalClient.succeed("dig +short A ${server_name} @127.0.0.1 -p 1090 | grep 216.58.211.1")

      # clash api
      normalClient.succeed("curl --fail --max-time 10 http://localhost:9090/proxies")

      # log
      tunClient.succeed("grep '216.58.211.1:443' /tmp/sing-box.log")
    '';

  }
)
