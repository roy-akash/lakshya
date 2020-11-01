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
 */
package cormen;

import java.util.Arrays;

public class InsertionSort {

    public static int[] arr = new int[]{5,2,4,6,1,3};

    public static int[] iSort(int[] arr){
        for (int j = 1 ; j<arr.length;j++){
            int i = j-1 , key = arr[j];
            while (i >= 0 && arr[i] > key){
                arr[i+1] = arr[i];
                i--;
            }
            arr[i+1] = key;
        }
        return arr;
    }

    public static int[] dSort(int[] arr){

        for(int j = 1; j < arr.length; j++){
            int i = j-1 , key = arr[j];
            while(i>=0 && arr[i] < key){
                arr[i+1] = arr[i];
                i--;
            }
            arr[i+1] = key;
        }
        return arr;
    }

    public static void main(String[] args) {
        System.out.println(Arrays.toString(iSort(arr)));
        System.out.println(Arrays.toString(dSort(arr)));
    }

}