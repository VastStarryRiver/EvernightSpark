using DG.Tweening;
using Invariable;
using TMPro;
using UnityEngine;
using UnityEngine.SceneManagement;



namespace HotUpdate
{
    public class MainPanel : UIPanel
    {
        public RectTransform m_tsTest;
        public TextMeshProUGUI m_textTest;
        public AudioClip m_audioBGM;
        public GameObject m_objBG;



        private void Awake()
        {
            GameManager.Instance.InvokeEventCallBack<object>(InvariableConst.Event_Launcher_StartGame, null); // 销毁热更新面板
        }

        private void Start()
        {
            PlayBGM();
            PlayBtnAnim();
        }



        /// <summary>
        /// 播放背景音乐
        /// </summary>
        private void PlayBGM()
        {
            AudioManager.Instance.PlayBGM(m_audioBGM);
        }

        /// <summary>
        /// 播放开始游戏按钮的动画
        /// </summary>
        private void PlayBtnAnim()
        {
            m_tsTest.DOAnchorPos(Vector2.zero, 1f).SetTarget(m_tsTest).SetEase(Ease.InSine).OnComplete(() =>
            {
                m_tsTest.DOAnchorPos(new Vector2(0, -200), 1f).SetTarget(m_tsTest).SetEase(Ease.OutSine);
            });
        }



        /// <summary>
        /// 测试功能1
        /// </summary>
        public void OnTestClick1()
        {
            YooAssetManager.Instance.AsyncLoadScene("Scenes_CandyScene_day", LoadSceneMode.Single, (scene) =>
            {
                Transform trans = GameObject.Find("CandyScene_day_Camera").transform;

                Utils.MainCamera.transform.localPosition = trans.localPosition;
                Utils.MainCamera.transform.localRotation = trans.localRotation;
                Utils.MainCamera.transform.localScale = trans.localScale;

                m_objBG.SetActive(false);
            });
        }

        /// <summary>
        /// 测试功能2
        /// </summary>
        public void OnTestClick2()
        {
            YooAssetManager.Instance.AsyncLoadAsset<GameObject>("Prefabs_EvilMage", (asset) =>
            {
                Transform trans = GameObject.Instantiate(asset, transform).transform;
                trans.localPosition = new Vector3(7526, 1085, -1783);
                trans.localRotation = Quaternion.Euler(0, 65, 0);
                trans.localScale = new Vector3(800, 800, 800);
            });
        }

        /// <summary>
        /// 测试功能3
        /// </summary>
        public void OnTestClick3()
        {
            ConfigManager.GetRoleRuneByID(11, (config) =>
            {
                if (this == null || m_textTest == null || config == null)
                {
                    return;
                }

                m_textTest.text = "写入云数据";

                SdkManager.Instance.SetCloudData("Param", config.Param.ToString());
            });

            SdkManager.Instance.SetCloudData("Score", "100");
            CloudManager.Instance.ReportRankScore("Score", 100);
        }

        /// <summary>
        /// 测试功能4
        /// </summary>
        public void OnTestClick4()
        {
            m_textTest.text = SdkManager.Instance.GetCloudData("Param", "无云数据");
        }
    }
}