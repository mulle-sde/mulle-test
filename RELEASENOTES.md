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
