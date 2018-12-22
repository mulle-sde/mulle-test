### 4.0.8

* fix parameter passing one more time

### 4.0.7

* pass parameters on the command line to run and build

### 4.0.6

* fix libexec install location

### 4.0.5

* fix version info

### 4.0.4

* use proper installer for mulle-test

### 4.0.3

* fix installer for mulle-test

### 4.0.2

* try to fix brew again

### 4.0.1

* fix brew formula, improve exekutor logging, remove find warning on linux

# 4.0.0

* big overhaul. the build part is now done with mulle-sde.
* this means mulle-test is now dependent on mulle-sde, unless you use ./build-test scripts
* started use of mulle-platform to query platform specifica (more to come)
* last version before move to mulle-sde for build


### 3.0.13

* fix some wordings to track changes in mulle-sde

### 3.0.12

* fix some ugliness

### 3.0.11

* fix wrong function call

### 3.0.10

* load a .mulle-test/etc/environment.sh config if present

### 3.0.9

* need a little mulle-sde support

### 3.0.8

* fix extremely stupid init bug

### 3.0.7

* fix dependencies

### 3.0.6

* fix CMakeLists.txt again and again and again and again

### 3.0.5

* fix CMakeLists.txt again and again and again

### 3.0.4

* fix CMakeLists.txt again and again

### 3.0.3

* fix CMakeLists.txt again

### 3.0.2

* fix CMakeLists.txt

### 3.0.1

* improved environment setup for standalone operation w/o mulle-sde

# 3.0.0

* mulle-test 3.0 renamed from mulle-tests 2
* init is now done my mulle-test. There is a separate -env for
* reorganized project


### 2.2.11

* Various small improvements

### 2.2.9

* if objc do not allow CC defaults from travis unless OBJC_DIALECT is set

### 2.2.5

* dial down the convenience to support gcc. TEST_LIBRARIES must be linked inside tests CMakeLists.txt now

### 2.2.3

* fix return code on fails, fix cmake

### 2.2.1

* Various small improvements

### 2.1.1

* use MULLE_TEST to get os-specific-libraries.txt

## 2.1.0

* use MULLE_TESTS CMAKEFLAGS to let mulle-configuration produce os-specific-libs.txt for linkage


# 2.0.0

* use cmake instead of make as the multiple source file test builder


### 1.1.1

* use mulle-build 3.8 for build-test.sh


# 1.0.1

* Finally versioned this.
