/**
 * Licensed to the Airtel International LLP (AILLP) under one
 * or more contributor license agreements.
 * The AILLP licenses this file to you under the AA License, Version 1.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.
 * <p>
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @author Akash Roy
 * @department Big Data Analytics Airtel Africa
 * @since Sat, 31-10-2020
 *
 */
/*
https://leetcode.com/problems/add-binary/
 */
package LeetCode;

public class AddBinary {

    /*
    "101111"
    "10"
     */
    public String addBinary(String a, String b) {
        char remainder = '0';
        StringBuilder ansBuilder = new StringBuilder();
        int i=a.length()-1,j=b.length()-1;
        for(;i>=0&&j>=0;i--,j--){
            if(a.charAt(i)=='1'&&b.charAt(j)=='1'){
                if(remainder == '1'){
                    ansBuilder.append('1');
                }else {
                    ansBuilder.append('0');
                    remainder = '1';
                }
            }else if (a.charAt(i)=='0'&&b.charAt(j)=='0'){
                if(remainder == '1'){
                    ansBuilder.append('1');
                    remainder = '0';
                }else {
                    ansBuilder.append('0');
                }
            }else {
                if(remainder == '1'){
                    ansBuilder.append('0');
                }else {
                    ansBuilder.append('1');
                }
            }
        }
        while (i>=0){
            if(remainder == '1'&&a.charAt(i)=='1'){
                ansBuilder.append('0');
            }else{
                if(remainder == '1'){
                    ansBuilder.append(remainder);
                    remainder = '0';
                }else{
                    ansBuilder.append(a.charAt(i));
                }
            }
            i--;
        }
        while (j>=0){
            if(remainder == '1'&&b.charAt(j)=='1'){
                ansBuilder.append('0');
            }else{
                if(remainder == '1'){
                    ansBuilder.append(remainder);
                    remainder = '0';
                }else{
                    ansBuilder.append(b.charAt(j));
                }
            }
            j--;
        }
        if(remainder == '1')
            ansBuilder.append(remainder);

        return ansBuilder.reverse().toString();
    }

    public static void main(String[] args) {
        AddBinary addBinary = new AddBinary();
        System.out.println(addBinary.addBinary("101111","10"));
    }
}