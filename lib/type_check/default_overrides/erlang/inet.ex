# # Overrides Erlang's `:inet` module:
defmodule Elixir.TypeCheck.DefaultOverrides.Erlang.Inet do
  use TypeCheck
#   @type! address_family() :: :inet | :inet6 | :local

#   @type! ancillary_data() :: [tos: byte(), tclass: byte(), ttl: byte()]

#   @typep! ether_address() :: [0..255]

#   @type! family_address() :: inet_address() | inet6_address() | local_address()

#   @typep! getifaddrs_ifopts() :: [
#     ifopt ::
#     {:flags,
#      flags :: [
#        :up
#        | :broadcast
#        | :loopback
#        | :pointtopoint
#        | :running
#        | :multicast
#      ]}
#     | {:addr, addr :: ip_address()}
#     | {:netmask, netmask :: ip_address()}
#     | {:broadaddr, broadaddr :: ip_address()}
#     | {:dstaddr, dstaddr :: ip_address()}
#     | {:hwaddr, hwaddr :: [byte()]}
#   ]

#   # TODO
#   @autogen_typespec false
#   @type! hostent() :: term()

#   @type! hostname() :: atom() | charlist()

#   @typep! if_getopt() ::
#   :addr | :broadaddr | :dstaddr | :mtu | :netmask | :flags | :hwaddr

#   @typep! if_getopt_result() ::
#   {:addr, ip_address()}
#   | {:broadaddr, ip_address()}
#   | {:dstaddr, ip_address()}
#   | {:mtu, non_neg_integer()}
#   | {:netmask, ip_address()}
#   | {:flags,
#      [
#        :up
#        | :down
#        | :broadcast
#        | :no_broadcast
#        | :pointtopoint
#        | :no_pointtopoint
#        | :running
#        | :multicast
#        | :loopback
#      ]}
#   | {:hwaddr, ether_address()}

#   @typep! if_setopt() ::
#   {:addr, ip_address()}
#   | {:broadaddr, ip_address()}
#   | {:dstaddr, ip_address()}
#   | {:mtu, non_neg_integer()}
#   | {:netmask, ip_address()}
#   | {:flags,
#      [
#        :up
#        | :down
#        | :broadcast
#        | :no_broadcast
#        | :pointtopoint
#        | :no_pointtopoint
#        | :running
#        | :multicast
#      ]}
#   | {:hwaddr, ether_address()}

#   @typep! inet6_address() ::
#   {:inet6, {ip6_address() | :any | :loopback, port_number()}}

#   @typep! inet_address() ::
#   {:inet, {ip4_address() | :any | :loopback, port_number()}}

#   @type! ip4_address() :: {0..255, 0..255, 0..255, 0..255}

#   @type! ip6_address() ::
#   {0..65535, 0..65535, 0..65535, 0..65535, 0..65535, 0..65535, 0..65535,
#    0..65535}

#   @type! ip_address() :: ip4_address() | ip6_address()

#   @type! local_address() :: {:local, file :: binary() | charlist()}

#   @typep! module_socket() :: {:"$inet", handler :: module(), handle :: term()}

  @type! port_number() :: 0..65535

#   @type! posix() ::
#   :eaddrinuse
#   | :eaddrnotavail
#   | :eafnosupport
#   | :ealready
#   | :econnaborted
#   | :econnrefused
#   | :econnreset
#   | :edestaddrreq
#   | :ehostdown
#   | :ehostunreach
#   | :einprogress
#   | :eisconn
#   | :emsgsize
#   | :enetdown
#   | :enetunreach
#   | :enopkg
#   | :enoprotoopt
#   | :enotconn
#   | :enotty
#   | :enotsock
#   | :eproto
#   | :eprotonosupport
#   | :eprototype
#   | :esocktnosupport
#   | :etimedout
#   | :ewouldblock
#   | :exbadport
#   | :exbadseq
#   | :file.posix()

#   # TODO
#   @type! returned_non_ip_address() :: {:local, binary()} | {:unspec, ""} | {:undefined, any()}

#   # TODO
#   @type socket() :: port() | module_socket()
#   @autogen_typespec false
#   @type! socket() :: term() | module_socket()

#   @type! socket_address() :: ip_address() | :any | :loopback | local_address()

#   @type! socket_getopt() ::
#   :gen_sctp.option_name()
#   | :gen_tcp.option_name()
#   | :gen_udp.option_name()

#   @type! socket_protocol() :: :tcp | :udp | :sctp

#   @type! socket_setopt() ::
#   :gen_sctp.option() | :gen_tcp.option() | :gen_udp.option()

#   @typep! socket_type() :: :stream | :dgram | :seqpacket

#   @type! stat_option() ::
#   :recv_cnt
#   | :recv_max
#   | :recv_avg
#   | :recv_oct
#   | :recv_dvi
#   | :send_cnt
#   | :send_max
#   | :send_avg
#   | :send_oct
#   | :send_pend

end
