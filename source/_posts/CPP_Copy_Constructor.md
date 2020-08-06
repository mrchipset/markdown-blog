---
title: C++ 构造函数和深拷贝、浅拷贝问题
tags:
  - C/C++
  - 内存管理
abbrlink: 4c55edde
date: 2020-07-23 23:08:51
---

本文将阐述C++类的拷贝构造函数和内存深拷贝和浅拷贝相关问题。C/C++为程序员提供了极大的内存管理自由度，成为了一把双刃剑。一方面指针的概念能够提供极高的运算性能，免去不必要的内存分配和拷贝的性能花销。另一方面需要程序员在编码过程中对内存管理有一个全局的把控和认识；初学者的一个疏忽很容易造成内存泄漏问题。因此对C/C++程序员来说，内存管理是学习过程当中非常重要的一章内容。由于篇幅有限本文将直接结合拷贝构造函数进行介绍。
<!--more-->

## 没有堆内存分配的类

首先我们先来编写一个所有成员变量都分配在栈上的测试类Foo，定义如下
```C++
class Foo
{
public:
    Foo(int val);
    void printMe();
private:
    int m_member;
};
```

类的实现如下
```C++
#include Foo.h
#include <iostream>


Foo::Foo(int val) 
    : m_member(val)
{

}

void Foo::printMe()
{
    std::cout << m_member: << m_member << &m_member: << &m_member << std::endl;
}
```

在main函数中写声明一个Foo类的实例bar1，再申明一个Foo类的实例bar2，默认拷贝构造自bar1

```C++
#include Foo.h

int main()
{
    Foo bar1(10);
    Foo bar2 = bar1;
    bar1.printMe();
    bar2.printMe();
    return 0;
}
```

编译运行后得到输出如下：
> m_member:10 &m_member:0x7ffeefbffda8<br> m_member:10 &m_member:0x7ffeefbffda0

## 将成员变量分配到堆上
得到了我们预期的结果，两个Foo类的实例值的输出一致，而成员的内存地址则不同。现在我们讲成员变量m_member声明成一个指针类型，在堆上进行分配内存后再进行默认拷贝。

首先，我们将m_member修改成int*类型，并在构造函数当中在堆上分配一个int型的内存并赋值。由于使用了堆内存，需要在析构函数中对内存进行释放，避免内存泄漏。修改完代码之后，我们再次运行代码，得到如下结果：
> m_member:10 &m_member:0x100300000<br>
m_member:10 &m_member:0x100300000<br>
P1_COPY_CONSTRUCTOR(10732,0x7fff88e4e380) malloc: *** error for object 0x100300000: pointer being freed was not allocated<br>
*** set a breakpoint in malloc_error_break to debug<br>

可以发现两个指针所指向的值是相同的，也就是说两个实例中的member在默认拷贝情况下指向同一块内存。那么理所应当的发生了报错，因为在析构函数当中，两个实例都释放了同一地址的内存。

从上面的两个实验，我们可以发现C++的内存拷贝策略，对于在栈内存上分配的成员进行深拷贝，堆上的成员变量则是浅拷贝。当默认拷贝构造函数无法满足我们的需求时，就需要我们手动编码拷贝构造函数，以自主掌控对象的拷贝行为。现在我们在原有代码的基础上增加一个拷贝构造函数，在进行指针型成员变量的拷贝时，手动进行深拷贝操作。
```C++
Foo::Foo(const Foo& other)
{
    m_member = new int;
    *m_member = *other.m_member;
}
````

修改完代码后，再次编译运行，我们可以得到预期的结果，成功地拷贝了原始对象的成员变量，拥有不同的内存地址，在析构地时候程序也不再报错。
> m_member:10 &m_member:0x100300000<br>
m_member:10 &m_member:0x100300010<br>
