import UIKit
var array = [1,2,3,4,5]
var ans = array.map {
    $0 % 2 == 0 ? $0 : $0 * $0
}
print(ans)
