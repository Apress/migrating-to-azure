#r "ICSharpCode.SharpZipLib.dll"
#r "Newtonsoft.Json"
#r "Microsoft.Azure.Documents.Client"
#r "Microsoft.WindowsAzure.Storage.dll"

using System;
using System.Linq;
using System.Net;
using Microsoft.Azure.WebJobs.Host;
using System.IO;
using ICSharpCode.SharpZipLib.Zip;
using Newtonsoft.Json;
using Microsoft.Azure.Documents;
using System.Collections;
using System.Collections.Generic;
using Microsoft.Azure;
using Microsoft.WindowsAzure.Storage;
using Microsoft.WindowsAzure.Storage.Blob;

public static object[] Run(Stream myBlob, string name, TraceWriter log)
{
    log.Info($"C# Blob trigger function Processed blob\n Name:{name} \n Size: {myBlob.Length} Bytes");
    RunOutput docInfo = new RunOutput();
    docInfo.RunId = name.Replace(".zip","");
    using (ICSharpCode.SharpZipLib.Zip.ZipInputStream str = new ICSharpCode.SharpZipLib.Zip.ZipInputStream(myBlob))
    {
        ZipEntry entry;
        while ((entry = str.GetNextEntry()) != null)
        {
            if (entry.IsFile)
            {
                log.Info(entry.Name);
                var info = new RunInfo();
                info.Uri = entry.Name;
                byte[] array = new byte[2048];
                int size = 0;
                string contents = "";
                while (true)
                {
                    size = str.Read(array, 0, array.Length);
                    if (size > 0)
                    {
                        contents += new System.Text.ASCIIEncoding().GetString(array, 0, size);
                    }
                    else
                    {
                        break;
                    }
                }
                //log.Info(contents);
                try
                {
                    var items = contents.Split('\n');
                    if(entry.Name == "links.txt") {
                        var listItems = items.ToList();
                        listItems.ForEach(i => {
                            if(i.Length > 1) {
                                var recs = i.Split(',');
                                docInfo.Urls.Add(recs[1],recs[0]);
                                if(listItems.First() == i) {
                                    docInfo.RunTime = DateTime.Parse(recs[3]);
                                    log.Info(docInfo.RunId);
                                    log.Info(docInfo.RunTime.ToString());
                                }
                            }
                        });
                    } else {
                        for (var i = 1; i < items.Count(); i++)
                    {
                        try
                        {
                            if (items[i].Length > 1)
                            {
                                var req = new RequestInfo(items[i]);
                                info.Requests.Add(req);
                            }
                        }
                        catch (Exception ex)
                        {
                            log.Info(items[i]);
                            throw ex;
                        }
                        info.RunId = docInfo.RunId;
                        docInfo.Runs.Add(info);
                    }
                    
                    }
                    
                }
                catch (Exception e)
                {
                    log.Error(e.StackTrace);
                }

            }

        }
    }
    docInfo.UpdateRunLinks();
    log.Info("Processing complete.");
    CloudStorageAccount storageAccount = CloudStorageAccount.Parse("DefaultEndpointsProtocol=https;AccountName=frankenstorage;AccountKey=koQHr72hrRaBYPF9kT5F+XfeIZ8fhp7nt6DuyQnRmnzTrVBukCOMxgcdtsjKx+zUztzxbf1rvUwERnvqimfY7g==");

    // Create the destination blob client
    CloudBlobClient blobClient = storageAccount.CreateCloudBlobClient();
    CloudBlobContainer container = blobClient.GetContainerReference("ab-test");
    var blockBlob = container.GetBlockBlobReference(name);
    
    if(blockBlob.DeleteIfExists()) {
        log.Info("Deleted source blob.");
    } else {
        log.Warning("Could not delete the source blob.");
    }
    return docInfo.Runs.ToArray();
}

[JsonObject]
public class RunOutput
{
    public List<RunInfo> Runs {get;set;}
    public string RunId {get;set;}
    public DateTime RunTime {get;set;}
    public Dictionary<string,string> Urls {get;set;}
    public RunOutput () {
        Runs = new List<RunInfo>();
        Urls = new Dictionary<string,string>();
    }
    
    public void UpdateRunLinks() {
        Runs.ForEach(r => {
            if(Urls.Keys.Contains(r.Uri)) {
                r.Uri = Urls[r.Uri];
            }
        });
       var tm = @"BULK INSERT Product
FROM 'data/product.dat'
WITH ( DATA_SOURCE = 'MyAzureBlobStorageAccount');";
    }
}

[JsonObject()]
public class RunInfo
{
    public RunInfo()
    {
        Requests = new List<RequestInfo>();
    }
    public string Uri { get; set; }
    public string RunId {get;set;}
    public List<RequestInfo> Requests { get; set; }
}

[JsonObject()]
public class RequestInfo
{
    public RequestInfo() { }

    public RequestInfo(string data)
    {
        var values = data.Split('\t');
        StartTime = values[0];
        Seconds = int.Parse(values[1]);
        CTime = int.Parse(values[2]);
        TTime = int.Parse(values[3]);
        WaitTime = int.Parse(values[4]);
    }

    public int WaitTime { get; set; }
    public int Seconds { get; set; }
    public string StartTime { get; set; }
    public int CTime { get; set; }
    public int TTime { get; set; }
}