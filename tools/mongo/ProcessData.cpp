#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <iostream>
#include <string>
#include <fstream>
using namespace std;

static char buff[1024] = {0};

int ProcessTimeStamp(ifstream* pinfile, ofstream* poutfile)
{
    int i = 0;
    while (pinfile->getline(buff, sizeof(buff)))
    {
        //skip first line
        if (0 == i)
        {
            *poutfile << buff << endl;
            i++;
        }
        else
        {
            char* p = strtok(buff, ",");
            time_t time = atoi(p);
            struct tm* stime = localtime(&time);
            *poutfile << 1900 + stime->tm_year << "-" << 1 + stime->tm_mon << "-" << stime->tm_mday \
                << " " << stime->tm_hour << ":" << stime->tm_min << ":" << stime->tm_sec;
            while (p = strtok(NULL, ","))
            {
                *poutfile << "\t," << (p);
            }
            *poutfile << endl;
        }
    }
    return 0;
}

int main(int argc,char *argv[])
{
    if (4 != argc)
    {
        cout << "argc" << argc << endl;
        return 0;
    }
    string dir = argv[1];
    string name = argv[2];
    string type = argv[3];

    char cwd[256] = {0};
    getcwd(cwd, sizeof(cwd));
    string scwd(cwd);
    string infilename = scwd + "/" + dir + "/" + name + "-" + dir + ".csv";
    string outfilename = scwd + "/" + dir + "/" + name + "-" + dir + "-" + type + ".csv";
    ifstream infile(infilename.c_str());
    ofstream outfile(outfilename.c_str());
    if (infile.is_open() && outfile.is_open())
    {
        if ("time" == type)
        {
            return ProcessTimeStamp(&infile, &outfile);
        }
        else if ("count" == type)
        {
        }
        else if ("distinct" == type)
        {
        }
    }
}



