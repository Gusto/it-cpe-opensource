# win_device_employee_admx

This profile ingests the ADMX defining "employee" registry keys and then sets the values via AD attribute lookups.

### Metadata

* Profile name: win_device_employee_admx
* Description: Defines 'employee' attributes ADMX for ingestion and configures values.
* Assignment Type: Auto
* Type: Device
* Payload: Custom Settings (of course)
* Target: OMA DM Client
* Make Commands Atomic: True

### Install Settings

```xml
<Replace><CmdID>0</CmdID><Item><Meta><Format>chr</Format><Type>text/plain</Type></Meta><Target><LocURI>./Vendor/MSFT/Policy/ConfigOperations/ADMXInstall/employee/Policy/employeeAdmxFilename</LocURI></Target><Data><![CDATA[<?xml version="1.0" encoding="UTF-8"?>
<policyDefinitions revision="1.0" schemaVersion="1.0">
   <policyNamespaces>
      <using prefix="employee" namespace="employee.Policies" />
      <using prefix="windows" namespace="Microsoft.Policies.Windows" />
   </policyNamespaces>
   <resources minRequiredRevision="1.0" />
   <supportedOn>
      <definitions>
         <definition displayName="SUPPORTED_WIN10" name="SUPPORTED_WIN10" />
      </definitions>
   </supportedOn>
   <categories>
      <category displayName="DefaultCategory" name="DefaultCategory">
      </category>
   </categories>
   <policies>
      <policy name="Subteam" class="Both" displayName="Subteam" key="Software\Policies\employee\Attributes" explainText="Subteam" presentation="String">
         <parentCategory ref="DefaultCategory" />
         <supportedOn ref="SUPPORTED_WIN10" />
         <elements>
            <text id="Subteam" valueName="Subteam" />
         </elements>
      </policy>
      <policy name="Team" class="Both" displayName="Team" key="Software\Policies\employee\Attributes" explainText="Team" presentation="String">
         <parentCategory ref="DefaultCategory" />
         <supportedOn ref="SUPPORTED_WIN10" />
         <elements>
            <text id="Team" valueName="Team" />
         </elements>
      </policy>
      <policy name="company" class="Both" displayName="company" key="Software\Policies\employee\Attributes" explainText="company" presentation="String">
         <parentCategory ref="DefaultCategory" />
         <supportedOn ref="SUPPORTED_WIN10" />
         <elements>
            <text id="company" valueName="company" />
         </elements>
      </policy>
      <policy name="physicalDeliveryOffice" class="Both" displayName="physicalDeliveryOffice" key="Software\Policies\employee\Attributes" explainText="physicalDeliveryOffice" presentation="String">
         <parentCategory ref="DefaultCategory" />
         <supportedOn ref="SUPPORTED_WIN10" />
         <elements>
            <text id="physicalDeliveryOffice" valueName="physicalDeliveryOffice" />
         </elements>
      </policy>
   </policies>
</policyDefinitions>]]></Data></Item></Replace>

<Replace>
  <CmdID>1</CmdID>
  <Item>
    <Target>
      <LocURI>./Device/Vendor/MSFT/Policy/Config/employee~Policy~DefaultCategory/company</LocURI>
    </Target>
    <Data>
      <![CDATA[<enabled/> <data id="company" value="{CustomAttribute5}"/>]]>
    </Data>
  </Item>
</Replace>

<Replace>
  <CmdID>2</CmdID>
  <Item>
    <Target>
      <LocURI>./Device/Vendor/MSFT/Policy/Config/employee~Policy~DefaultCategory/Team</LocURI>
    </Target>
    <Data>
      <![CDATA[<enabled/> <data id="Team" value="{CustomAttribute3}"/>]]>
    </Data>
  </Item>
</Replace>

<Replace>
  <CmdID>3</CmdID>
  <Item>
    <Target>
      <LocURI>./Device/Vendor/MSFT/Policy/Config/employee~Policy~DefaultCategory/Subteam</LocURI>
    </Target>
    <Data>
      <![CDATA[<enabled/> <data id="Subteam" value="{CustomAttribute4}"/>]]>
    </Data>
  </Item>
</Replace>
```

### Remove Settings

```xml
<Delete>
  <CmdID>1</CmdID>
  <Item>
    <Target>
      <LocURI>./Device/Vendor/MSFT/Policy/Config/employee~Policy~DefaultCategory/company</LocURI>
    </Target>
  </Item>
</Delete>

<Delete>
  <CmdID>2</CmdID>
  <Item>
    <Target>
      <LocURI>./Device/Vendor/MSFT/Policy/Config/employee~Policy~DefaultCategory/Team</LocURI>
    </Target>
  </Item>
</Delete>

<Delete>
  <CmdID>3</CmdID>
  <Item>
    <Target>
      <LocURI>./Device/Vendor/MSFT/Policy/Config/employee~Policy~DefaultCategory/Subteam</LocURI>
    </Target>
  </Item>
</Delete>
```
