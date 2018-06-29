class Octave < Formula
  desc "High-level interpreted language for numerical computing"
  homepage "https://www.gnu.org/software/octave/index.html"
  url "https://ftp.gnu.org/gnu/octave/octave-4.4.0.tar.gz"
  mirror "https://ftpmirror.gnu.org/octave/octave-4.4.0.tar.gz"
  sha256 "72f846379fcec7e813d46adcbacd069d72c4f4d8f6003bcd92c3513aafcd6e96"
  revision 1

  bottle do
    sha256 "9229aecdfaa4539e9954e234e0d4af6e13b1930d482af464e4e75d6ad2987c19" => :high_sierra
    sha256 "ac0be47ccbf61b6451aae5d98ba3f02e1ffd7a9cd264083e4751cc99877a6bb3" => :sierra
    sha256 "8868b5feec8daeb3266df99f99c3ea303e8ba22d95adc4a8257571473cd6ac21" => :el_capitan
  end

  head do
    url "https://hg.savannah.gnu.org/hgweb/octave", :branch => "default", :using => :hg

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "bison" => :optional
    depends_on "icoutils" => :build
    depends_on "librsvg" => :build
  end

  # Complete list of dependencies at https://wiki.octave.org/Building
  depends_on "gnu-sed" => :build # https://lists.gnu.org/archive/html/octave-maintainers/2016-09/msg00193.html
  depends_on :java => ["1.6+", :build, :test]
  depends_on "pkg-config" => :build
  depends_on "arpack"
  depends_on "epstool"  => :optional
  depends_on "fftw"
  depends_on "fig2dev" => :optional
  depends_on "fltk"
  depends_on "fontconfig"
  depends_on "freetype"
  depends_on "gcc" # for gfortran
  depends_on "ghostscript" => :optional
  depends_on "gl2ps" => :optional
  depends_on "glpk"
  depends_on "gnuplot"
  depends_on "graphicsmagick"
  depends_on "hdf5"
  depends_on "libsndfile"
  depends_on "libtool"
  depends_on "pcre"
  depends_on "portaudio"
  depends_on "pstoedit" => :optional
  depends_on "qhull"
  depends_on "qrupdate"
  depends_on "readline"
  depends_on "suite-sparse"
  depends_on "sundials"
  depends_on "texinfo"
  if OS.mac?
    depends_on "veclibfort"
  else
    depends_on "curl"
    depends_on "openblas" => :recommended
  end

  # Dependencies use Fortran, leading to spurious messages about GCC
  cxxstdlib_check :skip

  # If GraphicsMagick was built from source, it is possible that it was
  # done to change quantum depth. If so, our Octave bottles are no good.
  # https://github.com/Homebrew/homebrew-science/issues/2737
  def pour_bottle?
    Tab.for_name("graphicsmagick").without?("quantum-depth-32") &&
      Tab.for_name("graphicsmagick").without?("quantum-depth-8")
  end

  def install
    # Reduce memory usage below 4 GB for Circle CI.
    ENV["MAKEFLAGS"] = "-j8" if ENV["CIRCLECI"]

    # Default configuration passes all linker flags to mkoctfile, to be
    # inserted into every oct/mex build. This is unnecessary and can cause
    # cause linking problems.
    inreplace "src/mkoctfile.in.cc", /%OCTAVE_CONF_OCT(AVE)?_LINK_(DEPS|OPTS)%/, '""'

    blas_args = []
    if build.with? "openblas"
      blas_args << "--with-blas=-L#{Formula["openblas"].opt_lib} -lopenblas"
    elsif build.with? "veclibfort"
      blas_args << "--with-blas=-L#{Formula["veclibfort"].opt_lib} -lvecLibFort"
    else
      blas_args << "--with-blas=-lblas -llapack"
    end

    args = *blas_args + %W[
      --prefix=#{prefix}
      --disable-dependency-tracking
      --disable-silent-rules
      --enable-link-all-dependencies
      --enable-shared
      --disable-static
      --disable-docs
      --without-osmesa
      --without-qt
      --with-hdf5-includedir=#{Formula["hdf5"].opt_include}
      --with-hdf5-libdir=#{Formula["hdf5"].opt_lib}
      --with-x=no
      --with-portaudio
      --with-sndfile
    ]

    ENV['CFLAGS']=''
    ENV['CXXFLAGS']=''    
    system "./bootstrap" if build.head?
    system "./configure", *args
    system "make", "all"

    # Avoid revision bumps whenever fftw's or gcc's Cellar paths change
    inreplace "src/mkoctfile.cc" do |s|
      s.gsub! Formula["fftw"].prefix.realpath, Formula["fftw"].opt_prefix
      s.gsub! Formula["gcc"].prefix.realpath, Formula["gcc"].opt_prefix
    end

    # Make sure that Octave uses the modern texinfo at run time
    rcfile = buildpath/"scripts/startup/site-rcfile"
    rcfile.append_lines "makeinfo_program(\"#{Formula["texinfo"].opt_bin}/makeinfo\");"

    system "make", "install"
  end

  test do
    system bin/"octave", "--eval", "(22/7 - pi)/pi"
    # This is supposed to crash octave if there is a problem with veclibfort
    system bin/"octave", "--eval", "single ([1+i 2+i 3+i]) * single ([ 4+i ; 5+i ; 6+i])"
    # Test java bindings: check if javaclasspath is working, return error if not
    system bin/"octave", "--eval", "try; javaclasspath; catch; quit(1); end;"
  end
end
