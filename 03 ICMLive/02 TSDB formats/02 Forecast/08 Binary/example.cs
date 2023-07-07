using System;
using System.IO;

namespace binary_format
{
    class Program
    {
        static void Main(string[] args)
        {
            int nCols = 100;
            int nRows = 100;
            string fileName = @"c:\temp\2016110112_001.dat";
            using (BinaryWriter writer = new BinaryWriter(File.Open(fileName, FileMode.Create)))
            {
                for (int y = 0; y < nRows; y++)
                {
                    for (int n = 0; n < nCols; n++)
                    {
                        writer.Write(1.0F);
                    }
                }
            }
        }
    }
}
