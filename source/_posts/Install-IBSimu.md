---
title: Ubuntu发行版编译安装IBSimu等离子体数值计算工具集
tags:
  - Linux
  - 数值计算
  - 安装教程
  - C/C++
  - IBSimu
categories:
  - 安装教程
  - IBSimu
abbrlink: d54260e5
date: 2020-08-04 15:24:34
---

IBSimu 是由T. Klavas等人开发的一款遵循GPL协议开源的三维等离子体数值仿真计算工具集。虽然项目主页上有相对比较完备的安装、使用和应用的文档。由于比较小众，还是做一个记录，以供未来查阅备忘，更希望能为需要的人提供有一定价值的参考资料。

<!--more-->

## 演示环境

本文的演示环境为基于Micrsoft WSL内核的Ubuntu发行版，如果使用原生的Ubuntu发行版，过程与本文描述类似。其余的Linux发行版，由于使用的包管理器不同，可能在安装依赖环境过程会存在略微的差异，如有困难可发送邮件咨询笔者（Email地址可在本站关于页查看）。

代码可以从IBSimu的项目主页下载，也可以从笔者的Github代码仓库[下载](https://github.com/mrchipset/IBSimu.git)

## 安装依赖环境
由于需要从源代码编译IBSimu的源代码，我们需要先安装Ubuntu的构建工具包 `build-essential`。IBSimu的作者还使用了`autoconf, aclocal, automake, m4`等自动构建工具，因此这些工具也需要一定安装。

执行以下命令安装相应环境
> `sudo apt install build-essential autoconf automake`

编译构建工具的准备到这里就基本完成了。现在我们来分析IBSimu依赖的代码库，这里只分析笔者认为比较重要的代码库，部分可选的代码库并不影响编译过程将被忽略。

首先我们来分析autoconfigure的配置文件`configure.ac`，用文档查找工具查找`CHECK_`以快速定位依赖项。必要的依赖库见下表：

| 库名称     | 功能     |
| :------- | --------: |
| zlib |  提供通用的压缩功能  |
| gtk3    | 提供渲染支持    |
| gsl     | GNU 科学算法库     |
| libpng     | 将结果输出成png图片     |
| freetype     | 字体库     |

使用apt命令安装代码库，
>`sudo apt install zlib1g-dev libgtk-3-dev libgsl-dev`
笔者安装以上库即可通过`configure`，如在操作过程中报错，只需根据configure的输出内容安装相应的依赖库即可。

## 编译代码库
当`configure`完成后，运行`make`命令构建，构建完成后可以运行`make check`进行测试。当测试全部通过后，运行`make install`安装到系统的代码库中。

## 测试

当安装全部完成后，利用官方首页上的代码进行测试。测试代码如下, 笔者使用的是CMake和pkg-config来组织项目, CMake的使用并非本文的重点，不再零星赘述，读者可以查阅网络获取更多信息。

C++语言源代码
```C++
#include "epot_bicgstabsolver.hpp"
#include "geometry.hpp"
#include "func_solid.hpp"
#include "epot_efield.hpp"
#include "meshvectorfield.hpp"
#include "particledatabase.hpp"
#include "geomplotter.hpp"
#include "ibsimu.hpp"
#include "error.hpp"

bool solid1(double x, double y, double z)
{
    return (x <= 0.02 && y >= 0.018);
}

bool solid2(double x, double y, double z)
{
    return (x >= 0.03 && x <= 0.04 && y >= 0.02);
}

bool solid3(double x, double y, double z)
{
    return (x >= 0.06 && y >= 0.03 && y >= 0.07 - 0.5 * x);
}

void simu(void)
{
    Geometry geom(MODE_2D, Int3D(241, 101, 1), Vec3D(0, 0, 0), 0.0005);

    Solid *s1 = new FuncSolid(solid1);
    geom.set_solid(7, s1);
    Solid *s2 = new FuncSolid(solid2);
    geom.set_solid(8, s2);
    Solid *s3 = new FuncSolid(solid3);
    geom.set_solid(9, s3);

    geom.set_boundary(1, Bound(BOUND_DIRICHLET, -3.0e3));
    geom.set_boundary(2, Bound(BOUND_DIRICHLET, -1.0e3));
    geom.set_boundary(3, Bound(BOUND_NEUMANN, 0.0));
    geom.set_boundary(4, Bound(BOUND_NEUMANN, 0.0));
    geom.set_boundary(7, Bound(BOUND_DIRICHLET, -3.0e3));
    geom.set_boundary(8, Bound(BOUND_DIRICHLET, -14.0e3));
    geom.set_boundary(9, Bound(BOUND_DIRICHLET, -1.0e3));
    geom.build_mesh();

    EpotField epot(geom);
    MeshScalarField scharge(geom);
    MeshVectorField bfield;
    EpotEfield efield(epot);
    field_extrpl_e efldextrpl[6] = {FIELD_EXTRAPOLATE, FIELD_EXTRAPOLATE,
                                    FIELD_SYMMETRIC_POTENTIAL, FIELD_EXTRAPOLATE,
                                    FIELD_EXTRAPOLATE, FIELD_EXTRAPOLATE};
    efield.set_extrapolation(efldextrpl);

    EpotBiCGSTABSolver solver(geom);

    ParticleDataBase2D pdb(geom);
    bool pmirror[6] = {false, false, true, false, false, false};
    pdb.set_mirror(pmirror);

    for (size_t i = 0; i < 5; i++)
    {
        solver.solve(epot, scharge);
        efield.recalculate();
        pdb.clear();
        pdb.add_2d_beam_with_energy(1000, 50.0, 1.0, 1.0,
                                    3.0e3, 0.0, 0.0,
                                    0.0, 0.0,
                                    0.0, 0.012);
        pdb.iterate_trajectories(scharge, efield, bfield);
    }

    GeomPlotter geomplotter(geom);
    geomplotter.set_size(750, 750);
    geomplotter.set_epot(&epot);
    geomplotter.set_particle_database(&pdb);
    geomplotter.plot_png("plot1.png");
}

int main(int argc, char **argv)
{
    try
    {
        ibsimu.set_message_threshold(MSG_VERBOSE, 1);
        ibsimu.set_thread_count(4);
        simu();
    }
    catch (Error e)
    {
        e.print_error_message(ibsimu.message(0));
        exit(1);
    }

    return (0);
}
```

CMakeList.txt
```cmake
cmake_minimum_required(VERSION 3.0.0)
project(Vlasov2D VERSION 0.1.0)

find_package(PkgConfig)
pkg_check_modules(IBSimu ibsimu-1.0.6dev)

include_directories(${IBSimu_INCLUDE_DIRS})
LINK_DIRECTORIES(/usr/local/lib)
add_executable(Vlasov2D main.cpp)
target_link_libraries(Vlasov2D ${IBSimu_LIBRARIES})
```


如果运行正确，将会在运行目录下产生一张名为`plot1.png`的图片结果，如下图所示

![result](https://phonix.mrchip.info/PictureItems/AB93D6614CD6C0E8F305FAE079AC5039)
