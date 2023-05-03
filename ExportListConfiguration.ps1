
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
#Configuration Parameters - Need to update this 
$SiteURL="http://url.com/"
$ListName= "theList"
$XMLPath=".\ListDetails.xml"

#Get the Web and List                       
$Web = Get-SPWeb $SiteURL
$List = $Web.Lists.TryGetList($ListName)

#Create an XMLTextWriter object
$XMLWriter = New-Object System.XMl.XmlTextWriter($XMLPath,$Null)

#Write XML declaration
$XMLWriter.WriteStartDocument()

#Write root element
$XMLWriter.WriteStartElement("Fields")

#Iterate through each field in the list
foreach ($Field in $List.Fields) {
    #Write field element with attributes
    $XMLWriter.WriteStartElement("Field")
    $XMLWriter.WriteAttributeString("Title", $Field.Title)
    $XMLWriter.WriteAttributeString("InternalName", $Field.InternalName)
    $XMLWriter.WriteAttributeString("Type", $Field.Type)
    $XMLWriter.WriteEndElement()
}

#Write end of root element
$XMLWriter.WriteEndElement()

#Write end of XML document
$XMLWriter.WriteEndDocument()

#Close the XMLTextWriter object
$XMLWriter.Close()
