class Systemd < Formula
  desc "System and service manager"
  homepage "https://wiki.freedesktop.org/www/Software/systemd/"
  url "https://github.com/systemd/systemd/archive/v234.tar.gz"
  sha256 "da3e69d10aa1c983d33833372ad4929037b411ac421fb085c8cee79ae1d80b6a"
  revision 3
  head "https://github.com/systemd/systemd.git"
  # tag "linuxbrew"

  bottle do
    sha256 "66b631eb35da4691e489fbecb0cec19707bfd5212d070c589d91310d4292c182" => :x86_64_linux
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "coreutils" => :build
  depends_on "docbook-xsl" => :build
  depends_on "gettext" => :build
  depends_on "gperf" => :build
  depends_on "intltool" => :build
  depends_on "libtool" => :build
  depends_on "libxslt" => :build # for xsltproc
  depends_on "m4" => :build
  depends_on "pkg-config" => :build
  depends_on "expat"
  depends_on "libcap"
  depends_on "util-linux" # for libmount
  depends_on "libgpg-error" => :build

  patch do
    url "https://github.com/systemd/systemd/commit/227b8a762fea1458547be2cdf0e6e4aac0079730.diff?full_index=1"
    sha256 "3a123a6cba8cf1e27b2ace04f81c6d0a87e29c7a9900aa2ec1d1fea8e06656a8"
  end

  # src/core/dbus.c:1022:5: internal compiler error: Segmentation fault
  fails_with :gcc => "4.8"

  def install
    ENV.prepend_create_path "PERL5LIB", libexec/"lib/perl5"

    # Needed by intltool (xml::parser)
    ENV.prepend_path "PERL5LIB", "#{Formula["intltool"].libexec}/lib/perl5"

    # Fix error: unsupported reloc 42
    inreplace "configure.ac", "-Wl,-fuse-ld=gold", ""

    # Fix compilation error: file ./man/custom-html.xsl line 24 element import
    ENV["XML_CATALOG_FILES"] = "#{etc}/xml/catalog"

    system "./autogen.sh"
    system "./configure",
      "--disable-acl",
      "--disable-debug",
      "--disable-dependency-tracking",
      "--disable-silent-rules",
      "--prefix=#{prefix}",
      "--localstatedir=#{var}",
      "--sysconfdir=#{prefix}/etc",
      "--with-rootprefix=#{prefix}",
      "--with-sysvinit-path=#{prefix}/etc/init.d",
      "--with-sysvrcnd-path=#{prefix}/etc/rc.d",
      "--with-libgpg-error-prefix=#{Formula["libgpg-error"].opt_prefix}"
    system "make", "install"
  end

  test do
    system "#{bin}/systemd-path"
  end
end
